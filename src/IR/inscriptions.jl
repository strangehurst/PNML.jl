"""
Return default inscription value based on `PNTD`. Has meaning of unity, as in `one`.
"""
function default_inscription end
default_inscription(::PNTD) where {PNTD <: PnmlType} = one(Integer)
default_inscription(::PNTD) where {PNTD <: AbstractContinuousCore} = one(Float64)
default_inscription(pntd::PNTD) where {PNTD <: AbstractHLCore} = default_term(pntd)

#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Labels an Arc.
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
(inscription::PTInscription)() = inscription.value

#
#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Labels an Arc.
"""
struct HLInscription{TermType} <: HLAnnotation
    text::Maybe{String}
    term::Maybe{TermType} # structure
    com::ObjectCommon
end

"""
$(TYPEDSIGNATURES)
"""

HLInscription() = HLInscription(nothing, Term(), ObjectCommon())
HLInscription(s::AbstractString) = HLInscription(s, Term())
HLInscription(t::Term) = HLInscription(nothing, t)
HLInscription(s::AbstractString, t::Term) = HLInscription(s, t, ObjectCommon())

"""
Evaluate a [`HLInscription`](@ref). Returns a value of the same sort as _TBD_.
"""
(hlm::HLInscription)() = "HLInscription functor not implemented"
