# Some labels are not part of the Specicication.
# It defines meta-models on top of a core label mechanism.
# The only label defined in the core model is `Name`.
# Meta-models define labels, including: marking, inscription, condition, declaration.
# New, unknown, differemt labels may belong to a different meta-model.
# We handle such labels by using the `anyelement` mechansim that fills a DictType.
#
# Rates were the first use of this mechanim.
# NB: Part 3 of the specification has words about extensions. We should look someday.

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
    rate(t::Transition) -> Real

Return rate label value of `transition`.  Missing rate labels are defaulted to zero.

All net types may have a rate value type. Expected label XML: <rate> <text>0.3</text> </rate>

See [`rate_value_type`](@ref PNML.rate_value_type).
"""
function rate(transition)
    if has_labels(transition)
        l = labels(transition)
        if has_label(l, :rate)
            str = text_content(elements(@inbounds(get_label(l, :rate))))
            return PNML.number_value(PNML.rate_value_type(nettype(transition)), str)
        end
    end
    return zero(PNML.rate_value_type(nettype(transition)))
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
    #@show transition; flush(stdout) #! debug
    if has_labels(transition)
        ls = labels(transition)
        if has_label(ls, :delay)
            (tag, interval) = first(elements(@inbounds(get_label(ls, :delay))))
            tag == "interval"
            closure  = _attribute(interval, :closure) # from Parser

            if haskey(interval, "cn") # Expect at least one cn.
                cn = @inbounds interval["cn"]
                (isnothing(cn) || isempty(cn)) &&
                        throw(ArgumentError(string("<delay><interval> <cn> element is ", cn)))
                if cn isa Vector
                    n = Float64[PNML.number_value(Float64, x)::Float64 for x in cn]
                else
                    n = Float64[PNML.number_value(Float64, cn)::Float64]
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

#-----------------------------------------------------------------------------

"""
$(TYPEDSIGNATURES)
Find first :text in vx and return its :content as string.
"""
function text_content end

function text_content(vx::Vector{PNML.XDVT2})
    isempty(vx) && throw(ArgumentError("empty `Vector{XDVT}` not expected"))
    text_content(first(vx))
end

function text_content(d::DictType)
    x = get(d, "text", nothing)
    isnothing(x) && throw(ArgumentError("missing <text> element in $(d)"))
    return x
end
text_content(s::Union{String,SubString{String}}) = s

"""
Find an XML attribute. XMLDict uses symbols as keys. Value returned is a string.
"""
function _attribute(vx::DictType, key::Symbol)
    x = get(vx, key, nothing)
    isnothing(x) && throw(ArgumentError("missing $key value"))
    isa(x, AbstractString)|| throw(ArgumentError("wrong type for attribute value, expected AbstractString got $(typeof(vx[key]))"))
    return x
 end
