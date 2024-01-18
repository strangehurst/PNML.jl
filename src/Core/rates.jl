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
        interval = first(elements(get_label(transition, :delay)))
        closure  = _attribute(interval, :closure)

        if haskey(interval, "cn") # Expect at least one cn.
            cn = @inbounds interval["cn"]
            i(snothing(cn) || isempty(cn)) &&
                    throw(ArgumentError("<delay><interval> <cn> element is $cn"))
            n = Float64[number_value(Float64, x)::Float64 for x in cn]
        end

        if haskey(interval, "ci") # At most one ci named constant.
            ci = @inbounds interval["ci"]
            (isnothing(ci) || isempty(ci)) &&
                    throw(ArgumentError("<interval> <cn> element is $ci"))
            if contains(only(ci), r"infin|infty") #todo add others?
                Inf
            else
                error("<delay><interval><ci> may only contain infin|infty, found: $ci")
            end
        end

        return (closure, n[1], length(n) == 1 ? ci : n[2])
    end
    return ("closed", 0.0, 0.0)
end
