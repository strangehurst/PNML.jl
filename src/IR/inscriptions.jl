#-------------------
abstract type Inscription <: AbstractLabel end

#-------------------
"""
PTInscription labels an Arc instance.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct PTInscription{T<:Number}  <: Inscription
    value::T
    com::ObjectCommon
end

PTInscription(pdict::PnmlDict) =
    PTInscription(onnothing(pdict[:value],1), ObjectCommon(pdict))

convert(::Type{Maybe{PTInscription}}, pdict::PnmlDict) = PTInscription(pdict)

#-------------------
"""
HLInscription labels an Arc instance.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct HLInscription <: Inscription
    text::Maybe{String}
    structure::Maybe{PnmlLabel}
    com::ObjectCommon
end

HLInscription(pdict::PnmlDict) =
    HLInscription(pdict[:text], pdict[:structure], ObjectCommon(pdict))
convert(::Type{Maybe{HLInscription}}, pdict::PnmlDict) = HLInscription(pdict)
