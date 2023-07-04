"""
$(TYPEDEF)
$(TYPEDFIELDS)

Label of a Transition that determines when the transition fires.

# Examples

```jldoctest; setup=:(using PNML; using PNML: Condition)
julia> c = Condition(PnmlCoreNet(), false)
Condition(nothing, false, )

julia> c()
false

julia> c = Condition(PnmlCoreNet(), "xx", false)
Condition("xx", false, )

julia> c()
false
```
#TODO Add high-level
"""
struct Condition{PNTD, T} <: Annotation
    pntd::PNTD
    text::Maybe{String}
    value::T
    com::ObjectCommon
end

Condition(pntd, value) = Condition(pntd, nothing, value, ObjectCommon())
Condition(pntd, text::AbstractString, value) = Condition(pntd, text, value, ObjectCommon())

value(c::Condition) = c.value
common(c::Condition) = c.com

(c::Condition)() = _evaluate(value(c))

condition_type(::Type{T}) where {T <: PnmlType} = Condition{T, Bool}
condition_type(::Type{T}) where {T <: AbstractHLCore} = Condition{T, Term}

condition_value_type(::Type{T}) where {T <: PnmlType} = Bool
condition_value_type(::Type{T}) where {T <: AbstractHLCore} = Term
