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

"""
$(TYPEDSIGNATURES)
Evaluate an [`Inscription`](@ref)'s `value`.
"""
(inscription::Inscription)() = _evaluate(value(inscription))
