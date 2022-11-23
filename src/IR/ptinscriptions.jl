"""
$(TYPEDEF)
$(TYPEDFIELDS)

Labels an Arc.

# Examples

```jldoctest; setup=:(using PNML: PTInscription)
julia> i = PTInscription()
PTInscription(1, )

julia> i()
1

julia> i = PTInscription(3)
PTInscription(3, )

julia> i()
3
```
"""
struct PTInscription{T<:Union{Int,Float64}}  <: Annotation
    value::T
    com::ObjectCommon
end

PTInscription() = PTInscription(one(Int))
PTInscription(value::Union{Int,Float64}) = PTInscription(value, ObjectCommon())

"""
$(TYPEDSIGNATURES)
Evaluate a [`PTInscription`](@ref).
"""
(inscription::PTInscription)() = _evaluate(inscription.value)
