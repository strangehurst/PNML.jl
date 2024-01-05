"""
$(TYPEDEF)
$(TYPEDFIELDS)

Wrap value of rate label of a `Transition`.
"""
struct TransitionRate{T<:Number} <: Annotation
    value::T
end

Base.eltype(r::TransitionRate) = typeof(value(r))
value(r::TransitionRate) = r.value

"""
$(TYPEDSIGNATURES)

Return rate label value of `transition`.  Missing rate labels are defaulted to zero, or no delay.

Expected label XML: <rate> <text>0.3</text> </rate>

See [`rate_value_type`](@ref).
"""
function rate(transition)
    R = rate_value_type(nettype(transition)) # All net types have a rate value type.
    if has_label(transition, :rate)
        r = get_label(transition, :rate)
        str = text_content(elements(r))
        tro = TransitionRate(number_value(R, str))
        @assert eltype(tro) === R
        return value(tro)
    end
    return zero(R)
end
