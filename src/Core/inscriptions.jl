"""
$(TYPEDEF)
$(TYPEDFIELDS)

Labels an Arc.

# Examples

```jldoctest; setup=:(using PNML: Inscription)
julia> i = Inscription()
Inscription(1, )

julia> i()
1

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

Inscription() = Inscription(one(Int))
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
function inscriptiontype end

"""
Use PNML type as trait to select type of inscription.
"""
function inscriptionvaluetype end

inscriptiontype(::PnmlType) = Inscription
inscriptionvaluetype(::PnmlType) = Int
inscriptionvaluetype(::AbstractContinuousNet) = Float64
