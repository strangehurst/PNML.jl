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

Return rate label value of `transition`.  Missing rate labels are defaulted to zero.

All net types may have a rate value type. Expected label XML: <rate> <text>0.3</text> </rate>

See [`rate_value_type`](@ref).
"""
function rate(transition)
    tr = transition_rate(transition)::Maybe{TransitionRate}
    return !isnothing(tr) ? value(tr) : zero(rate_value_type(nettype(transition)))
end

transition_rate(transition) = begin
    if has_label(transition, :rate)
        str = text_content(elements(@inbounds(get_label(transition, :rate))))
        return TransitionRate(number_value(rate_value_type(nettype(transition)), str))
    end
    return nothing
end


"""
$(TYPEDSIGNATURES)

Return delay label value of `transition` as interval tuple: ("closure-string", left, right)
Missing delay labels default to ("closed", 0.0, 0.0) a.k.a. zero.

All net types may have a delay value type. Expected label XML: see MathML.
Only non-negative.

Supports
  - ("closed-open", 0.0, ∞)  -> [0.0, ∞)
  - ("open-closed", 2.0, 6.0 -> (2.0, 6.0]
  - ("open", 2.0, 6.0)       -> (2.0, 6.0)
  - ("closed", 2.0, 6.0)     -> [2.0, 6.0]
"""
function delay(transition)
    if has_label(transition, :delay)
        (tag, interval) = first(elements(@inbounds(get_label(transition, :delay))))
        tag == "interval"
        closure  = _attribute(interval, :closure)

        if haskey(interval, "cn") # Expect at least one cn.
            cn = @inbounds interval["cn"]
            (isnothing(cn) || isempty(cn)) &&
                    throw(ArgumentError("<delay><interval> <cn> element is $cn"))
            if cn isa Vector
                n = Float64[number_value(Float64, x)::Float64 for x in cn]
            else
                n = Float64[number_value(Float64, cn)::Float64]
            end
        end

        if haskey(interval, "ci") # At most one ci named constant.
            ci = @inbounds interval["ci"]
            (isnothing(ci) || isempty(ci)) &&
                    throw(ArgumentError("<interval> <ci> element is $ci"))
            if ci isa Vector
                i = Float64[_ci(x) for x in ci]
            else
                i = Float64[_ci(ci)]
            end
        end
        return (closure, n[1], length(n) == 1 ? i[1] : n[2])
    end
    return ("closed", 0.0, 0.0)
end

function _ci(i)
    if i == "infin" || i == "infty"
        return Inf
    else
        error("may only contain infin|infty, found: $ci")
    end
end
