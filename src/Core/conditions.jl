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
struct Condition{T} <: Annotation
    text::Maybe{String}
    value::T
    com::ObjectCommon
end

Condition(value) = Condition(nothing, value, ObjectCommon())
Condition(text::AbstractString, value) = Condition(text, value, ObjectCommon())

value(c::Condition) = c.value
common(c::Condition) = c.com

(c::Condition)() = _evaluate(value(c))

condition_type(::Type{T}) where {T <: PnmlType} = Condition{condition_value_type(T)}

condition_value_type(::Type{T}) where {T <: PnmlType} = Bool
condition_value_type(::Type{T}) where {T <: AbstractHLCore} = Term
