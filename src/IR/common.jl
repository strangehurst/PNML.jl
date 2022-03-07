"""
$(TYPEDEF)
$(TYPEDFIELDS)

Common infrastructure shared by PNML objects and labels.
Some optional incidental bits are shared by most PNML objects are also collected here.
"""
struct ObjectCommon
    name::Maybe{Name}
    graphics::Maybe{Graphics}
    tools::Maybe{Vector{ToolInfo}}
    labels::Maybe{Vector{PnmlLabel}}
end

"""
$(TYPEDSIGNATURES)
Wrap selected fields of `pdict`. Each defaults to `nothing`.
"""
ObjectCommon(pdict::PnmlDict) = ObjectCommon(
    get(pdict, :name, nothing),
    get(pdict, :graphics, nothing),
    get(pdict, :tools, nothing),
    get(pdict, :labels, nothing)
)

"Return `true` if `oc` has a `name` element."
has_name(oc::ObjectCommon) = !isnothing(oc.name)
has_xml(oc::ObjectCommon) = false

"Return `true` if has a `graphics` element."
has_graphics(::Any) = false
has_graphics(oc::ObjectCommon) = !isnothing(oc.graphics)

"Return `true` if has a `tools` element."
has_tools(::Any) = false
has_tools(oc::ObjectCommon) = !isnothing(oc.tools)

"Return `true` if there is a `labels` element."
has_labels(::Any) = false
has_labels(oc::ObjectCommon) = !isnothing(oc.labels)

# Could use introspection on every field if they are all Maybes.
Base.isempty(oc::ObjectCommon) = !(has_name(oc) ||
                                   has_graphics(oc) ||
                                   has_tools(oc) ||
                                   has_labels(oc))

function Base.empty!(oc::ObjectCommon)
    has_name(oc) && empty!(oc.name)
    has_graphics(oc) && empty!(oc.graphics)
    has_tools(oc) && empty!(oc.tools)
    has_labels(oc) && empty!(oc.labels)
end
