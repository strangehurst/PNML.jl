"""
$(TYPEDSIGNATURES)

Return [`AnyElement`](@ref) wraping a `tag` symbol and `tuple` holding
a well-formed XML node. See [`ToolInfo`](@ref) for one intended use-case.
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

The main use-case is to be wrapped in a [`PnmlLabel`](@ref), [`AnyElement`](@ref),
[`Term`](@ref) or other specialized label.
"""
function unclaimed_label(node::XMLNode, pntd::PnmlType, idregistry::PnmlIDRegistry)
    ha! = HarvestAny(_harvest_any!, pntd, idregistry) # Create a functor.
    x = ha!(node) # Apply functor.
    return Symbol(nodename(node)) => x
end

text_content(ucl) = if hasproperty(ucl.elements, :text)
    ucl.elements.text.content
elseif hasproperty(ucl.elements, :content)
    ucl.elements.content # Nonstandard fallback. Allows omitting text wapper (usually works?)?
else
    throw(ArgumentError("tag missing content"))
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

Return `NamedTuple` holding a well-formed XML `node`.

If element `node` has any children, each is placed in the dictonary with the
child's tag name symbol as the key, repeated tags produce a vector as the value.
Any XML attributes found are added as as key,value pairs.

Descend the well-formed XML using `parser` on child nodes.

Note the assumption that "children" and "content" are mutually exclusive.
Content is always a leaf element. However XML attributes can be anywhere in
the hierarchy. And neither children nor content nor attribute may be present.
"""
function _harvest_any!(node::XMLNode, ha!::HarvestAny)
    CONFIG.verbose && println("harvest ", nodename(node))
    tup = NamedTuple()
    # Extract XML attributes. Register IDs as symbols.
    for a in eachattribute(node)
        # ID attributes can appear in various places.
        # Each is unique, symbolized and added to the registry.
        # Other names have unmodified content (some string) as the value.
        val = a.name == "id" ? register_id!(ha!.reg, a.content) : a.content
        tup = merge(tup, (; Symbol(a.name) => val))
    end

    # Extract children or content.
    if haselement(node)
        children = EzXML.elements(node)
        #!_anyelement_content!(vec, children, ha!)
        tup = merge(tup, _anyelement_content(tup, children, ha!))
    elseif !isempty(EzXML.nodecontent(node))
        # <tag> </tag> will have nodecontent, though the whitespace is discarded.
        #!push!(vec, :content => (strip ∘ EzXML.nodecontent)(node))
        tup = merge(tup, (; :content => (strip ∘ EzXML.nodecontent)(node)))
    else
        # <tag/> and <tag></tag> will not have any nodecontent.
        #!push!(vec, :content => "")
        tup = merge(tup, (; :content => ""))
    end
    # @show vec
    return tup #(; vec...)
end

"""
$(TYPEDSIGNATURES)

Apply `ha!` to each node in `nodes`.
Return pairs Symbol => values that are vectors when there
are multiple instances of a tag in `nodes` and scalar otherwise.
"""
function _anyelement_content(tup::NamedTuple,
                             nodes::Vector{XMLNode},
                             ha!::HarvestAny)::NamedTuple

    namevec = Pair{String,XMLNode}[nodename(node) => node for node in nodes if node !== nothing] # Not yet Symbols.
    tagnames::Vector{String} = unique(map(first, namevec))

    CONFIG.verbose && @show tagnames

    for tagname in tagnames
        tags::Vector{Pair{String,XMLNode}} = collect(filter((Fix2(===, tagname) ∘ first), namevec))
        #tags = filter((Fix2(===, tagname) ∘ first), namevec)
        if length(tags) > 1
            #!push!(vec,  Symbol(tagname) => NamedTuple[ha!(t.second) for t in tags]) # Now its a symbol.)
            tup = merge(tup, (; Symbol(tagname) => NamedTuple[ha!(t.second) for t in tags])) # Now its a symbol.)
        else
            #!push!(vec,  Symbol(tagname) => ha!(tags[1].second)::NamedTuple) # Now its a symbol.)
            tup = merge(tup, (; Symbol(tagname) => ha!(tags[1].second)))# Now its a symbol.)
        end
    end

    return tup
end
