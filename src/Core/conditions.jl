"""
$(TYPEDEF)
$(TYPEDFIELDS)

Label of a Transition that determines when the transition fires.

# Examples

```jldoctest; setup=:(using PNML; using PNML: Condition)
julia> c = Condition(false)
Condition(nothing, false, )

julia> c()
false

julia> c = Condition("xx", false)
Condition("xx", false, )

julia> c()
false
```
"""
@auto_hash_equals struct Condition <: Annotation
    text::Maybe{String}
    value::Union{Bool, Term}
    com::ObjectCommon
end

Condition(value) = Condition(nothing, value, ObjectCommon())
Condition(text::AbstractString, value) = Condition(text, value, ObjectCommon())

value(c::Condition) = c.value
common(c::Condition) = c.com
Base.eltype(::Type{<:Condition}) = Bool # Output type of _evaluate

(c::Condition)() = _evaluate(value(c))::eltype(c)

condition_type(::Type{<:PnmlType}) = Condition

condition_value_type(::Type{<: PnmlType}) = Bool
condition_value_type(::Type{<: AbstractHLCore}) = eltype(BoolSort)
