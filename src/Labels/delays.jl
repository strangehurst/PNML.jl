# Split from rates.jl by JDH 2025-11-10
# PnmlLabel version
"""
$(TYPEDSIGNATURES)

Return delay label value as interval tuple: ("closure-string", left, right)
Missing delay labels default to ("closed", 0.0, 0.0) a.k.a. zero.

All net types may have a delay value type. Expected label XML: see MathML.
Only non-negative.
static transition
Supports
  - ("closed-open", 0.0, ∞)  -> [0.0, ∞)
  - ("open-closed", 2.0, 6.0 -> (2.0, 6.0]
  - ("open", 2.0, 6.0)       -> (2.0, 6.0)
  - ("closed", 2.0, 6.0)     -> [2.0, 6.0]
"""
function delay_value(t;
            tag::String = "delay",
            valtype::Type{<:Number} = Float64,
            content_parser::Base.Callable = delay_content_parser,
            default_value = tuple("closed", 0.0, 0.0))
    label = labelof(t, tag)
    d = if isnothing(label)
        default_value
    else
        D()&& @show label valtype
        content_parser(label, valtype)::Tuple
    end
    D()&& @show d
    return d
end

function delay_content_parser(label, value_type)
    (tag, interval) = first(elements(label))
    tag == "interval" || error("expected 'interval', found '$tag'")
    D()&& @show value_type
    closure = PNML._attribute(interval, :closure)
    D()&& @show closure

    # numbers
    n = if haskey(interval, "cn") # Expect at least one cn.
        let cn = @inbounds interval["cn"]
            (isnothing(cn) || isempty(cn)) &&
                throw(ArgumentError(string("<delay><interval> <cn> element is ", cn)))
            x = if cn isa Vector
                value_type[PNML.number_value(value_type, x) for x in cn]
            else
                value_type[PNML.number_value(value_type, cn)]
            end
            D()&& @show x
        end

    else
        throw(ArgumentError(string("<delay><interval> missing any <cn> element")))
    end
    D()&& @show n

    # ci is a symbol or variable in mathml
    i = if haskey(interval, "ci") # At most one ci named constant.
        let ci = @inbounds interval["ci"]
            (isnothing(ci) || isempty(ci)) &&
                throw(ArgumentError("<interval> <ci> element is $ci"))
            x = if ci isa Vector
                value_type[_ci(x) for x in ci]
            else
                value_type[_ci(ci)]
            end
        end
    else
        length(n) == 1 && throw(ArgumentError("<interval> <ci> element missing."))
    end
    D()&& @show n
    length(i) > 1 && throw(ArgumentError("<interval> has too many <ci> elements."))

    return tuple(closure, n[1], length(n) == 1 ? i[1] : n[2])
end

function _ci(i)
    if i == "infin" || i == "infty"
        return Inf
    else
        error("may only contain infin|infty, found: $ci")
    end
end
