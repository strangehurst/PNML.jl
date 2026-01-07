"""
$(TYPEDEF)
$(TYPEDFIELDS)

Real valued label. An expected use is as a transition rate.
Expected XML: `<rate> <text>0.3</text> </rate>`.
"""
@kwdef struct Rate{T<:PnmlExpr} <: Annotation
    #todo text
    term::T # Use the same mechanism as PTNet initialMarking and inscription.
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing
    declarationdicts::DeclDict
end

value_type(::Type{Rate}) = Float64
value_type(::Type{Rate}, ::PnmlType) = Float64

Base.eltype(::Rate) = value_type(Rate)

decldict(i::Rate) = i.declarationdicts
term(i::Rate) = i.term
sortref(i::Rate) = expr_sortref(term(i); ddict=decldict(i))::AbstractSortRef

sortof(i::Rate) = sortdefinition(namedsort(decldict(i), refid(sortref(i))))

function (rate::Rate)(varsub::NamedTuple=NamedTuple())
    eval(toexpr(term(rate), varsub, decldict(rate)))::value_type(Rate)
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
