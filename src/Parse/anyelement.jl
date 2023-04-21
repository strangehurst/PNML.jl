"""
$(TYPEDSIGNATURES)

Return [`AnyElement`](@ref) wraping a `tag` symbol and `Vector{Pair{Symbol}}` holding
a well-formed XML node.

See [`ToolInfo`](@ref) for one intended use-case.
"""
function anyelement end
anyelement(node::XMLNode, reg::PnmlIDRegistry) = anyelement(node, PnmlCoreNet(), reg)
function anyelement(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)::AnyElement
    @nospecialize
    AnyElement(unclaimed_label(node, pntd, reg), node)
end

"""
$(TYPEDSIGNATURES)

Return `tag` => `tuple` holding a pnml label and its children.

The main use-case is to be wrapped in a [`PnmlLabel`](@ref), [`Structure`](@ref),
[`Term`](@ref) or other specialized label. These wrappers add type to the
nested dictionary holding the contents of the label.
"""
function unclaimed_label(node::XMLNode, pntd::PnmlType, idregistry::PnmlIDRegistry)#!::Pair{Symbol,Vector{Pair{Symbol,Any}}}
    ha! = HarvestAny(_harvest_any!, pntd, idregistry)
    #x::Vector{Pair{Symbol,Any}}
    x = ha!(node)
    #!@show typeof(x) typeof((; x...))
    return Symbol(nodename(node)) => x
end

text_content(ucl) = if hasproperty(ucl.dict, :text)
    ucl.dict.text.content
elseif hasproperty(ucl.dict, :content)
    ucl.dict.content # Nonstandard fallback. Allows omitting text wapper (usually works?)?
else
    throw(ArgumentError("tag missing a content"))
end

# Expected patterns. Note only first is standard-conforming, extensible, prefeered.
#   <tag><text>1.23</text><tag>
#   <tag>1.23<tag>
# The unclaimed label mechanism adds a :content key for text XML elements.
# When the text element is elided, there is still a :content.
function numeric_label_value(T, ucl)
    @assert !isnothing(ucl)
    number_value(T, text_content(ucl))
end

# Functor
"""
Wrap a function and two of its arguments.
"""
struct HarvestAny
    #!fun::FunctionWrapper{Vector{Pair{Symbol,Any}}, Tuple{XMLNode, HarvestAny}}
    fun::FunctionWrapper{NamedTuple, Tuple{XMLNode, HarvestAny}}
    pntd::PnmlType
    reg::PnmlIDRegistry
end

(ha!::HarvestAny)(node::XMLNode) = ha!.fun(node, ha!)

"""
$(TYPEDSIGNATURES)

Return `PnmlDict` holding a well-formed XML `node`.

If element `node` has any children, each is placed in the dictonary with the
child's tag name symbol as the key, repeated tags produce a vector as the value.
Any XML attributes found are added as as key,value pairs.

Descend the well-formed XML using `parser` on child nodes.

Note the assumption that "children" and "content" are mutually exclusive.
Content is always a leaf element. However XML attributes can be anywhere in
the hierarchy. And neither children nor content nor attribute may be present.
"""
function _harvest_any!(node::XMLNode, ha!::HarvestAny)
    println("harvest ", nodename(node)) #! debug
    vec = Vector{Pair{Symbol,Any}}()
    # Extract XML attributes. Register IDs as symbols.
    for a in eachattribute(node)
        # ID attributes can appear in various places. Each is unique and added to the registry.
        push!(vec, Symbol(a.name) => a.name == "id" ? register_id!(ha!.reg, a.content) : a.content)
    end

    # Extract children or content.
    if haselement(node)
        children = elements(node)
        _anyelement_content!(vec, children, ha!)
    elseif !isempty(nodecontent(node))
        # <tag> </tag> will have nodecontent, though the whitespace is discarded.
        push!(vec, :content => (strip ∘ nodecontent)(node))
    else
        # <tag/> and <tag></tag> will not have any nodecontent.
        push!(vec, :content => "")
    end
    # @show vec
    return (; vec...)  #NamedTuple #of Pairs PnmlDict(vec)
end

"""
$(TYPEDSIGNATURES)

Apply `ha!` to each node in `nodes`.
Return pairs Symbol => values that are vectors when there
are multiple instances of a tag in `nodes` and scalar otherwise.
"""
function _anyelement_content!(vec::Vector{Pair{Symbol,Any}},
                              nodes::Vector{XMLNode},
                              ha!::HarvestAny)

    namevec = [nodename(node) => node for node in nodes if node !== nothing] # Not yet Symbols.
    tagnames = unique(map(first, namevec))
    @show tagnames

    for tagname in tagnames
        tags = collect(filter((Fix2(===, tagname) ∘ first), namevec))
        #tags = filter((Fix2(===, tagname) ∘ first), namevec)
        if length(tags) > 1
            push!(vec,  Symbol(tagname) => [ha!(t.second) for t in tags]) # Now its a symbol.)
        else
            push!(vec,  Symbol(tagname) => ha!(tags[1].second)) # Now its a symbol.)
        end
    end

    return nothing
end
