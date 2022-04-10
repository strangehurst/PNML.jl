"""
$(TYPEDSIGNATURES)

Return [`AnyElement`](@ref) wraping `PnmlDict` holding a well-formed XML node.
See [`ToolInfo`](@ref) for the intended use-case and [`unclaimed_label`](@ref) for when
a pnml label is expected but does not have a parser or the tag appears in an 
unexpected place.
"""
function anyelement end
anyelement(node; kw...) =  anyelement(node, PnmlCore(); kw...)
function anyelement(node, pntd; kw...)::AnyElement    
    @debug "anyelement = $(nodename(node))"

    d = _harvest_any!(node, pntd, anyelement; kw...)
    return AnyElement(d, node)
end

"""
$(TYPEDSIGNATURES)

Return `PnmlDict` holding a pnml label and its children.
Note that the children have `parse_node` applied recursivly and can be "claimed" labels.
The main use-case is to wrap in a [`PnmlLabel`](@ref)
"""
function unclaimed_label end
unclaimed_label(node; kw...) = unclaimed_label(node, PnmlCore(); kw...)
function unclaimed_label(node, pntd; kw...)::PnmlDict
    @debug "unclaimed = $(nodename(node))"
    @assert haskey(kw, :reg)
    # ID attributes can appear in various places. Each is unique and added to the registry.
    EzXML.haskey(node, "id") && register_id!(kw[:reg], node["id"])
    # Children may be claimed.
    return _harvest_any!(node, pntd, parse_node; kw...)
end

"""
$(TYPEDSIGNATURES)

Return `PnmlDict` holding parsed contents of a well-formed XML node.

If element `node` has any children, each is placed in the dictonary with the
child's tag name symbol as the key, repeated tags produce a vector as the value.
Any XML attributes found are added as as key,value pairs.

Descend the well-formed XML using `parser` on child nodes.
It is possible that claimed labels will be in the unclaimed element's content.

Note the assumption that "children" and "content" are mutually exclusive.
Content is always a leaf element. However XML attributes can be anywhere in
the hiearchy.
"""
function _harvest_any!(node::XMLNode, pntd::PNTD, parser; kw...)::PnmlDict where {PNTD<:PnmlType}
    # Extract XML attributes.
    dict = PnmlDict(:tag => Symbol(nodename(node)),
                 (Symbol(a.name) => a.content for a in eachattribute(node))...)
    # Extract children or content
    children = elements(node)
    if !isempty(children)
        merge!(dict, anyelement_content(children, parser; kw...))
    elseif !isempty(nodecontent(node))
        dict[:content] = strip(nodecontent(node))
    end
    return dict
end

"""
$(TYPEDSIGNATURES)

Apply `parser` to each node in `nodes`.
Return PnmlDict with values that are vectors when there 
are multiple instances of a tag in `nodes` and scalar otherwise.
"""
function anyelement_content(nodes::Vector{XMLNode}, parser; kw...)::PnmlDict
    namevec = [nodename(node) => node for node in nodes] # Not yet turned into Symbols.
    tagnames = unique(map(first, namevec))
    dict = PnmlDict()
    foreach(tagnames) do tagname
        tags = filter(x->x.first===tagname, namevec)
        dict[Symbol(tagname)] = if length(tags) > 1 # Now its a symbol.
            parser.(map(x->x.second, tags); kw...) # vector
        else
            parser(tags[1].second; kw...) # scalar
        end
    end
    return dict
end
