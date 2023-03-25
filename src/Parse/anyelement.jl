"""
$(TYPEDSIGNATURES)

Return [`AnyElement`](@ref) wraping a `tag` symbol and `PnmlDict` holding
a well-formed XML node.

See [`ToolInfo`](@ref) for one intended use-case.
"""
function anyelement end
anyelement(node::XMLNode, reg) = anyelement(node, PnmlCoreNet(), reg)
function anyelement(node::XMLNode, pntd::PnmlType, reg)::AnyElement
    @nospecialize
    AnyElement(unclaimed_label(node, pntd, reg), node)
end

"""
$(TYPEDSIGNATURES)

Return `tag` => `PnmlDict` holding a pnml label and its children.

The main use-case is to be wrapped in a [`PnmlLabel`](@ref), [`Structure`](@ref),
[`Term`](@ref) or other specialized label. These wrappers add type to the
nested dictionary holding the contents of the label.
"""
function unclaimed_label(node::XMLNode, pntd::PnmlType, reg)::Pair{Symbol,PnmlDict}
    ha! = HarvestAny(_harvest_any!, pntd, reg)
    dict = ha!(node)
    return Symbol(nodename(node)) => dict
end

# Functor
struct HarvestAny
    fun::FunctionWrapper{PnmlDict, Tuple{XMLNode, HarvestAny}}
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
    vec = Vector{Pair}()
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
    @show vec
    return PnmlDict(vec)
end

"""
$(TYPEDSIGNATURES)

Apply `ha!` to each node in `nodes`.
Return pairs Symbol => values that are vectors when there
are multiple instances of a tag in `nodes` and scalar otherwise.
"""
function _anyelement_content!(vec::Vector{Pair}, nodes::Vector{XMLNode}, ha!::HarvestAny)

    namevec = [nodename(node) => node for node in nodes if node !== nothing] # Not yet Symbols.
    tagnames = unique(map(first, namevec))
    @show tagnames

    for tagname in tagnames
        tags = filter((Fix2(===, tagname) ∘ first), namevec)
        push!(vec, Symbol(tagname) => [ha!(t.second) for t in tags]) # Now its a symbol.)
    end

#           if length(tags) > 1
#            [ha!(t.second) for t in tags] # vector #! NOT iterator
#       else
#           ha!(tags[1].second) # scalar
#       end)
    @show length(vec) vec typeof(vec)
    return nothing
end
