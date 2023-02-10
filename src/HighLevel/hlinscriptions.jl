"""
$(TYPEDEF)
$(TYPEDFIELDS)

Labels an Arc.

# Examples

```jldoctest; setup=:(using PNML; using PNML: HLInscription, PnmlDict, Term)
julia> i2 = HLInscription(Term(:term, PnmlDict(:value=>3)))
HLInscription(nothing, Term(:term, IdDict{Symbol, Any}(:value => 3)), )

julia> PnmlDict
IdDict{Symbol, Any}

julia> i2()
3

julia> i3 = HLInscription("text", Term())
HLInscription("text", Term(:empty, IdDict{Symbol, Any}()), )

julia> i3()
1

julia> i4 = HLInscription("text", Term(:term, PnmlDict(:value=>3)))
HLInscription("text", Term(:term, IdDict{Symbol, Any}(:value => 3)), )

julia> i4()
3
```
"""
struct HLInscription{T<:Term} <: HLAnnotation
    text::Maybe{String}
    term::T # <structure> content must be a many-sorted algebra term.
    com::ObjectCommon
end

HLInscription(s::AbstractString) = HLInscription(s, Term(:empty, PnmlDict(:value => zero(Int))))
HLInscription(t::Term) = HLInscription(nothing, t)
HLInscription(s::Maybe{AbstractString}, t) = HLInscription(s, t, ObjectCommon())

value(i::HLInscription) = i.term
common(i::HLInscription) = i.com

"""
$(TYPEDSIGNATURES)
Evaluate a [`HLInscription`](@ref). Returns a value of the same sort as _TBD_.
"""
(hli::HLInscription)() = _evaluate(value(hli))

inscription_type(::Type{T}) where{T<:AbstractHLCore} = HLInscription{inscription_value_type(T)}
inscription_value_type(::Type{<:AbstractHLCore}) = Term{PnmlDict}
