"""
$(TYPEDEF)
$(TYPEDFIELDS)

Labels an Arc.

# Examples

```jldoctest; setup=:(using PNML; using PNML: HLInscription, PnmlDict, Term)
julia> i2 = HLInscription(Term(:term, (; :value=>3)))
HLInscription(nothing, Term(:term, (value = 3,)), )

julia> i2()
3

julia> i3 = HLInscription("text", Term())
HLInscription("text", Term(:empty, ()), )

julia> i3()
1

julia> i4 = HLInscription("text", Term(:term, (; :value=>3)))
HLInscription("text", Term(:term, (value = 3,)), )

julia> i4()
3
```
"""
struct HLInscription{T<:Term} <: HLAnnotation
    text::Maybe{String}
    term::T # <structure> content must be a many-sorted algebra term.
    com::ObjectCommon
end

HLInscription(s::AbstractString) = HLInscription(s, Term(:empty, (; :value => zero(Int))))
HLInscription(t::Term) = HLInscription(nothing, t)
HLInscription(s::Maybe{AbstractString}, t) = HLInscription(s, t, ObjectCommon())

value(i::HLInscription) = i.term
common(i::HLInscription) = i.com

"""
$(TYPEDSIGNATURES)
Evaluate a [`HLInscription`](@ref). Returns a value of the same sort as _TBD_.
"""
(hli::HLInscription)() = _evaluate(value(hli))

inscription_type(::Type{T}) where{T<:AbstractHLCore} = HLInscription{Term}
inscription_value_type(::Type{<:AbstractHLCore}) = Int
