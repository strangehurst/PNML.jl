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

"""
Use PNML type as trait to select type of inscription.
"""
function inscription_type end

"""
Use PNML type as trait to select type of inscription.
"""
function inscription_value_type end

inscription_type(::Type{T}) where {T <: PnmlType} = Inscription{Int}
inscription_type(::Type{T}) where {T <: AbstractContinuousNet} = Inscription{Float64}

inscription_value_type(::Type{T}) where {T <: PnmlType} = Int
inscription_value_type(::Type{<:AbstractContinuousNet}) = Float64
