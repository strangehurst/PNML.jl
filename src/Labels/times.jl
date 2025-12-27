# Created 2025-11-10
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Real valued label. An expected use is for a Time Petri net.
Expected XML: `<time> <text>0.3</text> </time>`.

Dynamic time is a function with arguments of net marking and transition.
"""
@kwdef struct Time{T<:PnmlExpr} <: Annotation
    #todo text
    term::T # Use the same mechanism as PTNet initialMarking and inscription.
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing
    declarationdicts::DeclDict
end

value_type(::Type{Time}) = Float64
value_type(::Type{Time}, ::PnmlType) = Float64

Base.eltype(::Time) = value_type(Time)

decldict(i::Time) = i.declarationdicts
term(i::Time) = i.term
sortref(i::Time) = expr_sortref(term(i); ddict=decldict(i))::AbstractSortRef
sortof(i::Time) = sortdefinition(namedsort(decldict(i), sortref(i)))::Number

function (time::Time)(varsub::NamedTuple=NamedTuple())
    eval(toexpr(term(time), varsub, decldict(time)))::value_type(Time)
end

value(r::Time) = r()

function Base.show(io::IO, r::Time)
    print(io, "Time(", r.term, ", ", repr(r.graphics),  ", ", repr(r.toolspecinfos), ")")
end

"""
    time_value(t) -> Real

Return value of a `Time` label.  Missing time labels are defaulted to one.

Expected label XML: `<time> <text>0.3</text> </time>`

# Arguments
    `t` is anything that supports `labelof(t, tag)`.
"""
function time_value(t)
    label_value(t, :time, value_type(Time), one)::value_type(Time)
end
