"""
PNML Condition labels a Transition instance.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct Condition <: AbstractLabel
    text::Maybe{String}
    structure::Maybe{PnmlLabel}
    com::ObjectCommon
end

Condition(pdict::PnmlDict) = Condition(pdict[:text],
                                       pdict[:structure],
                                       ObjectCommon(pdict))
#convert(::Type{Maybe{Condition}}, d::PnmlDict) = Condition(d)
