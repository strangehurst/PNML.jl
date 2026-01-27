#---------------------------------------------------------------------
# LABELS
#--------------------------------------------------------------------
#! Extension point. user supplied parser -> Annotation.
# Could do conversion from xmldict.
#! 2 collections, one for PnmlLabels other for other Annotations?

"""
    add_label!(collection, node, pntd) -> AbstractDict

Parse and add [`PnmlLabel`](@ref) to collection, return collection.

See [`AbstractPnmlObject`](@ref) for those XML entities that have labels.
Any "unknown" XML is presumed to be a label.
"""
function add_label!(v::AbstractDict{Symbol,Any}, node::XMLNode, pntd, net)
    xd = xmldict(node)
    tag = Symbol(EzXML.nodename(node))
    v[tag] = PnmlLabel(tag, xd, net)
    return v
end

#---------------------------------------------------------------------
# TOOLINFO
#---------------------------------------------------------------------
"""
    add_toolinfo!(collection, node, pntd, parse_contex) -> collection

Parse and add [`ToolInfo`](@ref) to `infos` collection, return `infos`.

The UML from the _pnml primer_ (and schemas) use <toolspecific>
as the tag name for instances of the type ToolInfo.
"""
function add_toolinfo!(infos::Vector{ToolInfo}, node, pntd, net)
    return push!(infos, parse_toolspecific(node, pntd; net))
end

"""
    add_toolinfo(infos::Maybe{collection}, node::XMLNode, pntd, parse_contex) -> collection

Allocate storage for `infos` on first use. Then add to `infos`.
"""
function add_toolinfo(infos::Maybe{Vector{ToolInfo}}, node::XMLNode, pntd, net)
    i = isnothing(infos) ? ToolInfo[] : infos
    return add_toolinfo!(i, node, pntd, net)
end
