#---------------------------------------------------------------------
# LABELS
#--------------------------------------------------------------------

function add_label!(v::Vector{PnmlLabel}, node::XMLNode, pntd)
    #! Extension point. user supplied parser of DictType -> Annotation. Could do conversion after/on demand.
    #! 2 collections, one for PnmlLabels other for other Annotations?
    return push!(v, PnmlLabel(unparsed_tag(node)...))
end
function add_label(v::Maybe{Vector{PnmlLabel}}, node::XMLNode, pntd)
    labels = isnothing(v) ? PnmlLabel[] : v
    return add_label!(labels, node, pntd)
end
#---------------------------------------------------------------------
# TOOLINFO
#---------------------------------------------------------------------
"""
$(TYPEDSIGNATURES)

Add [`ToolInfo`](@ref) to `infos`, return nothing.

The UML from the _pnml primer_ (and schemas) use <toolspecific>
as the tag name for instances of the type ToolInfo.
"""
function add_toolinfo!(infos::Vector{ToolInfo}, node, pntd)
    push!(infos, parse_toolspecific(node, pntd))
    return infos
end

add_toolinfo(infos::Maybe{Vector{ToolInfo}}, node::XMLNode, pntd) = begin
    i = isnothing(infos) ? ToolInfo[] : infos
    return add_toolinfo!(i, node, pntd)
end
