"""
$(TYPEDEF)
$(TYPEDFIELDS)

Common infrastructure shared by PNML objects and labels.
Some optional incidental bits are shared by most PNML objects are also collected here.
"""
struct ObjectCommon
    graphics::Maybe{Graphics}
    tools::Maybe{Vector{ToolInfo}}
    labels::Maybe{Vector{PnmlLabel}}
end

ObjectCommon(pdict::PnmlDict) = ObjectCommon(
    get(pdict, :graphics, nothing),
    get(pdict, :tools, nothing),
    get(pdict, :labels, nothing)
)
ObjectCommon() = ObjectCommon(nothing, nothing, nothing)

"Return `true` if has a `graphics` element."
has_graphics(::Any) = false
has_graphics(oc::ObjectCommon) = !isnothing(oc.graphics)

"Return `true` if has a `tools` element."
has_tools(::Any) = false
has_tools(oc::ObjectCommon) = !isnothing(oc.tools)

"Return `true` if there is a `labels` element."
has_labels(::Any) = false
has_labels(oc::ObjectCommon) = !isnothing(oc.labels)

graphics(oc::ObjectCommon) = oc.graphics
tools(oc::ObjectCommon) = oc.tools
labels(oc::ObjectCommon) = oc.labels

# Could use introspection on every field if they are all Maybes.
Base.isempty(oc::ObjectCommon) = !(has_graphics(oc) ||
                                   has_tools(oc) ||
                                   has_labels(oc))

function Base.empty!(oc::ObjectCommon)
    has_graphics(oc) && empty!(oc.graphics)
    has_tools(oc) && empty!(oc.tools)
    has_labels(oc) && empty!(oc.labels)
end

function Base.append!(l::ObjectCommon, r::ObjectCommon)
    # In the flatten use-case do not overwrite scalars.
    # How useful is propagating scalars?
    # Note that ObjectCommon is immutable so these error.
    #if !has_name(l);     l.name     = r.name; end
    #if !has_graphics(l); l.graphics = r.graphics; end

    update_maybe!(l, r, :tools)
    update_maybe!(l, r, :labels)
end
