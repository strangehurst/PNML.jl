"""
$(TYPEDEF)
$(TYPEDFIELDS)

Common infrastructure shared by PNML objects and labels.
Some optional incidental bits are shared by most PNML objects are also collected here.
"""
struct ObjectCommon
    graphics::Maybe{Graphics}
    tools::Maybe{Vector{ToolInfo}} #! #TODO Make toolinfo generic.
    labels::Maybe{Vector{PnmlLabel}} #! #TODO Make label generic.
end

function ObjectCommon(pdict::PnmlDict)
    @assert haskey(pdict, :graphics)
    @assert haskey(pdict, :tools)
    @assert haskey(pdict, :labels)
    g = pdict[:graphics]::Maybe{Graphics}
    t = pdict[:tools]::Maybe{Vector{ToolInfo}}
    l = pdict[:labels]::Maybe{Vector{PnmlLabel}}
    ObjectCommon(g, t, l)
end
ObjectCommon() = ObjectCommon(nothing, nothing, nothing)

has_graphics(oc::ObjectCommon) = oc.graphics !== nothing
has_tools(oc::ObjectCommon)    = oc.tools !== nothing
has_labels(oc::ObjectCommon)   = oc.labels !== nothing
graphics(oc::ObjectCommon)     = oc.graphics
tools(oc::ObjectCommon)        = oc.tools
labels(oc::ObjectCommon)       = oc.labels

Base.isempty(oc::ObjectCommon) = !(has_graphics(oc) ||
                                   (has_tools(oc) && !isempty(oc.tools)) ||
                                   (has_labels(oc) && !isempty(oc.labels)))

function Base.empty!(oc::ObjectCommon)
    #! isnothing(oc.graphics) || replace with Graphics()
    t = oc.tools # JET needs help avoiding the Nothing union split.
    if !isnothing(t)
        empty!(t)
    end
    l = oc.labels
    if !isnothing(l)
        empty!(l)
    end
end

function Base.append!(l::ObjectCommon, r::ObjectCommon)
    # In the flatten use-case do not overwrite scalars.
    # How useful is propagating scalars?
    #! Note that ObjectCommon is immutable so these error.
    #! if !has_name(l);     l.name     = r.name; end
    #! if !has_graphics(l); l.graphics = r.graphics; end

    update_maybe!(l, r, :tools)
    update_maybe!(l, r, :labels)
end
