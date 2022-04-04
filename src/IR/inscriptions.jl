"""
Return default inscription value based on `PNTD`. Has meaning of unity, as in `one`.
"""
function default_inscription end
default_inscription(::PNTD) where {PNTD <: PnmlType} = one(Integer)
default_inscription(::PNTD) where {PNTD <: AbstractContinuousCore} = one(Float64)
default_inscription(::PNTD) where {PNTD <: AbstractHLCore} = nothing

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

#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Labels an Arc.
"""
struct HLInscription <: HLAnnotation
    text::Maybe{String}
    term::Maybe{Term} # structure
    com::ObjectCommon
end

"""
$(TYPEDSIGNATURES)
"""
#HLInscription(#pdict::PnmlDict) =
#    HLInscript##ion(pdict[:text], pdict[:structure], ObjectCommon(pdict))
#convert(::Type###{Maybe{HLInscription}}, pdict::PnmlDict) = HLInscription(pdict)##

HLInscription() = HLInscription(nothing,Term(),ObjectCommon())
HLInscription(s::AbstractString) = HLInscription(s, Term())
HLInscription(t::Term) = HLInscription(nothing, t)
HLInscription(s::AbstractString, t::Term) = HLInscription(s, t, ObjectCommon())
