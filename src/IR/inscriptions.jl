"""
Return default inscription value based on `PNTD`. Has meaning of unity, as in `one`.

# Examples

```jldoctest; setup=:(using PNML; using PNML: default_inscription)
julia> i = default_inscription(PnmlCore())
1

julia> i = default_inscription(ContinuousNet())
1.0

julia> i = default_inscription(HLCore())
Term(:empty, Dict(:value => 1))

julia> i()
1

```
"""
function default_inscription end
default_inscription(::PNTD) where {PNTD <: PnmlType} = one(Integer)
default_inscription(::PNTD) where {PNTD <: AbstractContinuousCore} = one(Float64)
default_inscription(pntd::PNTD) where {PNTD <: AbstractHLCore} = default_one_term(pntd)

#-------------------
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
struct PTInscription{T<:Number}  <: Annotation
    value::T
    com::ObjectCommon
end

PTInscription() = PTInscription(one(Int))
PTInscription(value) = PTInscription(value, ObjectCommon()) 

"""
Evaluate a [`PTInscription`](@ref).
"""
(inscription::PTInscription)() = _evaluate(inscription.value)

#
#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Labels an Arc.

# Examples

```jldoctest; setup=:(using PNML; using PNML: HLInscription, Term)
julia> i = HLInscription()
HLInscription(nothing, Term(:empty, Dict()), )

julia> i()
1

julia> i = HLInscription(Term(:term, PnmlDict(:value=>3)))
HLInscription(nothing, Term(:term, Dict(:value => 3)), )

julia> i()
3

julia> i = HLInscription("text", Term())
HLInscription("text", Term(:empty, Dict()), )

julia> i()
1

julia> i = HLInscription("text", Term(:term, PnmlDict(:value=>3)))
HLInscription("text", Term(:term, Dict(:value => 3)), )

julia> i()
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
Evaluate a [`HLInscription`](@ref). Returns a value of the same sort as _TBD_.
"""
(inscription::HLInscription)() = _evaluate(inscription.term)
