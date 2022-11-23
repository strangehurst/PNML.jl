"""
$(TYPEDEF)
$(TYPEDFIELDS)

Labels an Arc.

# Examples

```jldoctest; setup=:(using PNML; using PNML: HLInscription, Term)
julia> i1 = HLInscription()
HLInscription(nothing, Term(:empty, Dict()), )

julia> i1()
1

julia> i2 = HLInscription(Term(:term, PnmlDict(:value=>3)))
HLInscription(nothing, Term(:term, Dict(:value => 3)), )

julia> i2()
3

julia> i3 = HLInscription("text", Term())
HLInscription("text", Term(:empty, Dict()), )

julia> i3()
1

julia> i4 = HLInscription("text", Term(:term, PnmlDict(:value=>3)))
HLInscription("text", Term(:term, Dict(:value => 3)), )

julia> i4()
3
```
"""
struct HLInscription{TermType<:AbstractTerm} <: HLAnnotation
    text::Maybe{String}
    "Any <structure> must be a many-sorted algebra term for a <hlinscription> annotation label."
    term::Maybe{TermType} # structure
    com::ObjectCommon
end

HLInscription() = HLInscription(nothing, Term(), ObjectCommon())
HLInscription(s::AbstractString) = HLInscription(s, Term())
HLInscription(t::Term) = HLInscription(nothing, t)
HLInscription(s::Maybe{AbstractString}, t::Term) = HLInscription(s, t, ObjectCommon())

"""
$(TYPEDSIGNATURES)
Evaluate a [`HLInscription`](@ref). Returns a value of the same sort as _TBD_.
"""
(inscription::HLInscription)() = _evaluate(inscription.term)
