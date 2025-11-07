#---------------------------------------------------------------------
# LABELS
#--------------------------------------------------------------------
#! Extension point. user supplied parser -> Annotation.
# Could do conversion from xmldict.
#! 2 collections, one for PnmlLabels other for other Annotations?

"""
    add_label!(collection, node, pntd) -> collection

Parse and add [`PnmlLabel`](@ref) to collection, return collection.

See [`AbstractPnmlObject`](@ref) for those XML entities that have labels.
Any "unknown" XML is presumed to be a label.
"""
function add_label!(v::Vector{PnmlLabel}, node::XMLNode, pntd, ctx::ParseContext)
    # `xmldict` returns a ordered collection of `AnyElement`.
    return push!(v, PnmlLabel(xmldict(node)..., ctx.ddict))
end

"""
    add_label(infos::Maybe{collection}, node::XMLNode, pntd, parse_context) -> collection

Allocate storage for collection on first use. Then parse and add a label.
"""
function add_label(v::Maybe{Vector{PnmlLabel}}, node::XMLNode, pntd, ctx::ParseContext)
    labels = isnothing(v) ? PnmlLabel[] : v
    return add_label!(labels, node, pntd, ctx)
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
function add_toolinfo!(infos::Vector{ToolInfo}, node, pntd, parse_context::ParseContext)
    return push!(infos, parse_toolspecific(node, pntd; parse_context))
end

"""
    add_toolinfo(infos::Maybe{collection}, node::XMLNode, pntd, parse_contex) -> collection

Allocate storage for `infos` on first use. Then add to `infos`.
"""
function add_toolinfo(infos::Maybe{Vector{ToolInfo}}, node::XMLNode, pntd, ctx::ParseContext)
    i = isnothing(infos) ? ToolInfo[] : infos
    return add_toolinfo!(i, node, pntd, ctx)
end
