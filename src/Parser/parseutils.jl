#---------------------------------------------------------------------
# LABELS
#--------------------------------------------------------------------
#! Extension point. user supplied parser -> Annotation.
# Could do conversion from unparsed_tag.
#! 2 collections, one for PnmlLabels other for other Annotations?

"""
    add_label!(collection, node, pntd) -> collection

Parse and add [`PnmlLabel`](@ref) to collection, return collection.

See [`AbstractPnmlObject`](@ref) for those XML entities that have labels.
Any "unknown" XML is presumed to be a label.
"""
function add_label!(v::Vector{PnmlLabel}, node::XMLNode, pntd, ddict)
    return push!(v, PnmlLabel(unparsed_tag(node)..., ddict))
end

"""
    add_label(infos::Maybe{collection}, node::XMLNode, pntd) -> collection

Allocate storage for collection on first use. Then parse and add a label.
"""
function add_label(v::Maybe{Vector{PnmlLabel}}, node::XMLNode, pntd, ddict)
    labels = isnothing(v) ? PnmlLabel[] : v
    return add_label!(labels, node, pntd, ddict)
end

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Maps a `Symbol` to a parser callable for a `<labeltag>` tag's well-formed contents.
The parser will be called as func(node, pntd) and return
"""
@auto_hash_equals struct LabelParser
    tag::Symbol
    func::Base.Callable
end

"Name of xml tag."
PNML.tag(lp::LabelParser) = lp.tag

"Callable."
func(lp::LabelParser) = lp.func

#---------------------------------------------------------------------
# TOOLINFO
#---------------------------------------------------------------------
"""
    add_toolinfo!(collection, node, pntd) -> collection

Parse and add [`ToolInfo`](@ref) to `infos` collection, return `infos`.

The UML from the _pnml primer_ (and schemas) use <toolspecific>
as the tag name for instances of the type ToolInfo.
"""
function add_toolinfo!(infos::Vector{ToolInfo}, node, pntd, ddict)
    return push!(infos, parse_toolspecific(node, pntd; ddict))
end

"""
    add_toolinfo(infos::Maybe{collection}, node::XMLNode, pntd) -> collection

Allocate storage for `infos` on first use. Then add to `infos`.
"""
function add_toolinfo(infos::Maybe{Vector{ToolInfo}}, node::XMLNode, pntd, ddict)
    i = isnothing(infos) ? ToolInfo[] : infos
    return add_toolinfo!(i, node, pntd, ddict)
end
