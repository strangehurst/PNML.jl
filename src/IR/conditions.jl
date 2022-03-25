"""
Label of a Transition.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct Condition <: HLAnnotation
    text::Maybe{String}
    term::Maybe{Term} # structure
    com::ObjectCommon
end

"$(TYPEDSIGNATURES)"
Condition(pdict::PnmlDict) = Condition(pdict[:text],
                                       pdict[:structure],
                                       ObjectCommon(pdict))
