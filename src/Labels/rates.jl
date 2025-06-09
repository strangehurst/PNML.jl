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

Real valued label. An expected use is as a transition rate.
"""
@kwdef struct Rate{T<:Number} <: Annotation
    value::T # text? PnmlExpr?
    graphics::Maybe{Graphics} = nothing
    tools::Maybe{Vector{ToolInfo}} = nothing
    declarationdicts::DeclDict
end

Base.eltype(r::Rate) = typeof(value(r))
value(r::Rate) = r.value

function Base.show(io::IO, r::Rate)
    print(io, nameof(typeof(r)), "(", r.value, ", ", r,graphicd,  ", ", r.tools, ")")
end

"Parse content of `<text>` as a number of `value_type`."
function number_content_parser(label, value_type)
    #@show label value_type #! debug
    str = PNML.text_content(elements(label))
    PNML.number_value(value_type, str)::Number
 end

"""
    rate_value(t) -> Real

Return value of a `Rate` label.  Missing rate labels are defaulted to zero.

Expected label XML: `<rate> <text>0.3</text> </rate>`

# Arguments
    `t` is anything that supports `labelof(t, tag)`.
    `tag::String` is the XML element tag, default `"rate"`.
    `value_type::Type{<:Number}` is concrete `Type` used to parse value.
    `content_parser`::Base.Callable with arguments of `labelof(t, tag)` and `value_type`.
    `default_value` = zero(value_type) is returned when `labelof(t, tag)` returns `nothing`.
"""
function rate_value(t;
            tag::String = "rate",
            value_type::Type{<:Number} = PNML.value_type(Rate, nettype(t)),
            content_parser::Base.Callable = number_content_parser,
            default_value = zero(value_type),)
    label = labelof(t, tag)
    if isnothing(label)
        default_value
    else
        content_parser(label, value_type)
    end
end

value_type(::Type{Rate}, ::Type{<:PnmlType}) = Float64


#######################################################################################
#^#####################################################################################
#######################################################################################

"""
$(TYPEDSIGNATURES)

Return delay label value as interval tuple: ("closure-string", left, right)
Missing delay labels default to ("closed", 0.0, 0.0) a.k.a. zero.

All net types may have a delay value type. Expected label XML: see MathML.
Only non-negative.

Supports
  - ("closed-open", 0.0, ∞)  -> [0.0, ∞)
  - ("open-closed", 2.0, 6.0 -> (2.0, 6.0]
  - ("open", 2.0, 6.0)       -> (2.0, 6.0)
  - ("closed", 2.0, 6.0)     -> [2.0, 6.0]
"""
function delay_value(t;
            tag::String = "delay",
            value_type::Type{<:Number} = Float64,
            content_parser::Base.Callable = delay_content_parser,
            default_value = tuple("closed", 0.0, 0.0))
    label = labelof(t, tag)
    if isnothing(label)
        default_value
    else
        content_parser(label, value_type)
    end
end

function delay_content_parser(label, value_type)
    (tag, interval) = first(elements(label))
    tag == "interval" || error("expected 'interval', found '$tag'")
    closure  = PNML._attribute(interval, :closure)

    n = if haskey(interval, "cn") # Expect at least one cn.
        let cn = @inbounds interval["cn"]
            (isnothing(cn) || isempty(cn)) &&
                throw(ArgumentError(string("<delay><interval> <cn> element is ", cn)))
            if cn isa Vector
                value_type[PNML.number_value(value_type, x) for x in cn]
            else
                value_type[PNML.number_value(value_type, cn)]
            end
        end
    else
        throw(ArgumentError(string("<delay><interval> missing any <cn> element")))
    end

    i = if haskey(interval, "ci") # At most one ci named constant.
        let ci = @inbounds interval["ci"]
            (isnothing(ci) || isempty(ci)) &&
                throw(ArgumentError("<interval> <ci> element is $ci"))
            if ci isa Vector
                value_type[_ci(x) for x in ci]
            else
                value_type[_ci(ci)]
            end
        end
    else
        length(n) == 1 && throw(ArgumentError("<interval> <ci> element missing."))
    end
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
