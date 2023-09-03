"""
$(TYPEDEF)
$(TYPEDFIELDS)

Labels an Arc. The <structure> element is a term in a many-sorted algebra.
The `term` field TBD.
See also [`Inscription`](@ref)

# Examples

```jldoctest; setup=:(using PNML; using PNML: HLInscription, Term)
julia> i2 = HLInscription(Term(:value, 3))
HLInscription(nothing, Term(:value, 3), )

julia> i2()
3

julia> i3 = HLInscription("text", Term(:empty, 1))
HLInscription("text", Term(:empty, 1), )

julia> i3()
1

julia> i4 = HLInscription("text", Term(:value, 3))
HLInscription("text", Term(:value, 3), )

julia> i4()
3
```
"""
struct HLInscription{T<:Term} <: HLAnnotation
    text::Maybe{String}
    term::T # Content of <structure> content must be a many-sorted algebra term.
    com::ObjectCommon
end

HLInscription(t::Term) = HLInscription(nothing, t)
HLInscription(s::Maybe{AbstractString}, t) = HLInscription(s, t, ObjectCommon())

text(i::HLInscription)  = i.text
value(i::HLInscription) = i.term
common(i::HLInscription) = i.com

"""
$(TYPEDSIGNATURES)
Evaluate a [`HLInscription`](@ref). Returns a value of the same sort as _TBD_.
"""
(hli::HLInscription)() = _evaluate(value(hli))

inscription_type(::Type{T}) where{T<:AbstractHLCore} = HLInscription{Term}
inscription_value_type(::Type{<:AbstractHLCore}) = eltype(DotSort())
