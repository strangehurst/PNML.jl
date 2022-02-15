"""
Label of a Transition.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct Condition <: AbstractLabel
    text::Maybe{String}
    structure::Maybe{PnmlLabel}
    com::ObjectCommon
end

"$(TYPEDSIGNATURES)"
Condition(pdict::PnmlDict) = Condition(pdict[:text],
                                       pdict[:structure],
                                       ObjectCommon(pdict))
