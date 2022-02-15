#-------------------
"""
$(TYPEDEF)
"""
abstract type Inscription <: AbstractLabel end

#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Labels an Arc.
"""
struct PTInscription{T<:Number}  <: Inscription
    value::T
    com::ObjectCommon
end

"""
$(TYPEDSIGNATURES)
"""
PTInscription(pdict::PnmlDict) =
    PTInscription(onnothing(pdict[:value],1), ObjectCommon(pdict))

convert(::Type{Maybe{PTInscription}}, pdict::PnmlDict) = PTInscription(pdict)

#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Labels an Arc.
"""
struct HLInscription <: Inscription
    text::Maybe{String}
    structure::Maybe{PnmlLabel}
    com::ObjectCommon
end

"""
$(TYPEDSIGNATURES)
"""
HLInscription(pdict::PnmlDict) =
    HLInscription(pdict[:text], pdict[:structure], ObjectCommon(pdict))
convert(::Type{Maybe{HLInscription}}, pdict::PnmlDict) = HLInscription(pdict)
