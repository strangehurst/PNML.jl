"""
$(TYPEDEF)
$(TYPEDFIELDS)

Labels an Arc.

# Examples

```jldoctest; setup=:(using PNML: Inscription)
julia> i = Inscription(3)
Inscription(3, )

julia> i()
3
```
"""
struct Inscription{T<:Union{Int,Float64}}  <: Annotation
    value::T
    com::ObjectCommon
end

Inscription(value::Union{Int,Float64}) = Inscription(value, ObjectCommon())

value(i::Inscription) = i.value
common(i::Inscription) = i.com

"""
$(TYPEDSIGNATURES)
Evaluate an [`Inscription`](@ref)'s `value`.
"""
(inscription::Inscription)() = _evaluate(value(inscription))

inscription_type(::Type{T}) where {T <: PnmlType} = Inscription{inscription_value_type(T)}

inscription_value_type(::Type{<: PnmlType}) = Int
inscription_value_type(::Type{<:AbstractContinuousNet}) = Float64
