"""
$(TYPEDEF)
$(TYPEDFIELDS)

Label of a Transition that determines when the transition fires.

# Examples

```jldoctest; setup=:(using PNML; using PNML: Condition)
julia> c = Condition(false)
Condition(nothing, false, nothing, [])

julia> c()
false

julia> c = Condition("xx", false)
Condition("xx", false, nothing, [])

julia> c()
false
```
"""
@auto_hash_equals struct Condition <: Annotation
    text::Maybe{String}
    value::Union{Bool, Term}
    graphics::Maybe{Graphics}
    tools::Vector{ToolInfo}
end

Condition(value) = Condition(nothing, value, nothing, ToolInfo[])
Condition(text::AbstractString, value) = Condition(text, value, nothing, ToolInfo[])

value(c::Condition) = c.value
Base.eltype(::Type{<:Condition}) = Bool # Output type of _evaluate

(c::Condition)() = _evaluate(value(c))::eltype(c)

condition_type(::Type{<:PnmlType}) = Condition

condition_value_type(::Type{<: PnmlType}) = Bool
condition_value_type(::Type{<: AbstractHLCore}) = eltype(BoolSort)
