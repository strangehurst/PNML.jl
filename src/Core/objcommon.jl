"""
$(TYPEDEF)
$(TYPEDFIELDS)

Common infrastructure shared by PNML objects and labels.
Some optional incidental bits are shared by most PNML objects are also collected here.
"""
@kwdef struct ObjectCommon #! Make whole ObjectCommon a Maybe?
    graphics::Maybe{Graphics} = nothing
    tools::Vector{ToolInfo}   = ToolInfo[] #! #TODO Make toolinfo generic. tuple?
    labels::Vector{PnmlLabel} = PnmlLabel[] #! #TODO Make label generic. tuple?
end

function ObjectCommon(tup::NamedTuple)
    args = NamedTuple()
    #dump(tup)
    hasproperty(tup, :graphics) && (args = merge(args, (graphics = tup.graphics,)))
    hasproperty(tup, :tools)  && !isnothing(tup.tools) && (args = merge(args, (tools = tup.tools,)))
    hasproperty(tup, :labels) && !isnothing(tup.labels) && (args = merge(args, (labels = tup.labels,)))
    #@show args
    ObjectCommon(; args...)
end

has_graphics(oc::ObjectCommon) = oc.graphics !== nothing
has_tools(oc::ObjectCommon)    = !isempty(oc.tools)
has_labels(oc::ObjectCommon)   = !isempty(oc.labels)

graphics(oc::ObjectCommon)     = oc.graphics
tools(oc::ObjectCommon)        = oc.tools
labels(oc::ObjectCommon)       = oc.labels

Base.isempty(oc::ObjectCommon) = !(has_graphics(oc) || has_tools(oc) || has_labels(oc))

function Base.empty!(oc::ObjectCommon)
    #! isnothing(oc.graphics) || replace with Graphics()
    empty!(oc.tools)
    empty!(oc.labels)
end

function Base.append!(l::ObjectCommon, r::ObjectCommon)
    # In the flatten use-case do not overwrite scalars.
    # How useful is propagating scalars?
    #! Note that ObjectCommon is immutable so these error.
    #! if !has_graphics(l); l.graphics = r.graphics; end

    _update_maybe!(l, r, :tools)
    _update_maybe!(l, r, :labels)
end