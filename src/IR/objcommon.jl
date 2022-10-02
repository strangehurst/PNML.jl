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

has_graphics(oc::ObjectCommon) = oc.graphics !== nothing
has_tools(oc::ObjectCommon) = oc.tools !== nothing #!&& !isempty(oc.tools)
has_labels(oc::ObjectCommon) = oc.labels !== nothing #!&& !isempty(oc.labels)
graphics(oc::ObjectCommon) = oc.graphics
tools(oc::ObjectCommon) = oc.tools
labels(oc::ObjectCommon) = oc.labels

Base.isempty(oc::ObjectCommon) = !(has_graphics(oc) ||
                                   (has_tools(oc) && !isempty(oc.tools)) ||
                                   (has_labels(oc) && !isempty(oc.labels)))

function Base.empty!(oc::ObjectCommon)
    #! isnothing(oc.graphics) || replace with Graphics()
    #has_tools(oc)
    if oc.tools !== nothing
        # JET needs help avoiding the Nothing union split.
        t::Vector{ToolInfo} = oc.tools
        empty!(t)
    end
    if has_labels(oc)
        l::Vector{PnmlLabel} = oc.labels
        empty!(l)
    end
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
