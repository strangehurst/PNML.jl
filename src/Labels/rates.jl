"""
$(TYPEDEF)
$(TYPEDFIELDS)

Real valued label. An expected use is as a transition rate.
Expected XML: `<rate> <text>0.3</text> </rate>`.
"""
@kwdef struct Rate{T<:PnmlExpr, N <: AbstractPnmlNet} <: Annotation
    text::Maybe{String} = nothing
    term::T # Use the same mechanism as PTNet initialMarking and inscription.
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing
    net::N
end

value_type(::Type{Rate}) = Float64
value_type(::Type{Rate}, ::PnmlType) = Float64

Base.eltype(::Rate) = value_type(Rate)

term(r::Rate) = r.term
sortref(r::Rate) = expr_sortref(term(r), r.net)::SortRef
sortof(r::Rate) = sortdefinition(namedsort(r.net, refid(sortref(r))))

function (rate::Rate)(varsub::NamedTuple=NamedTuple())
    eval(toexpr(term(rate), varsub, rate.net))::value_type(Rate)
end

value(r::Rate) = r()

function Base.show(io::IO, r::Rate)
    print(io, "Rate(", r.term, ", ", repr(r.graphics),  ", ", repr(r.toolspecinfos), ")")
end

"""
    rate_value(t) -> Real

Return value of a `Rate` label.  Missing rate labels are defaulted to zero.

Expected label XML: `<rate> <text>0.3</text> </rate>`

# Arguments
    `t` is anything that supports `get_label(t, tag)`.
"""
function rate_value(t)
    label_value(t, :rate, value_type(Rate), zero)::value_type(Rate)
end
