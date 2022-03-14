"""
Label of a Transition.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct Condition <: HLAnnotation
    text::Maybe{String}
    structure::Maybe{Structure{AnyElement}}
    com::ObjectCommon
end

"$(TYPEDSIGNATURES)"
Condition(pdict::PnmlDict) = Condition(pdict[:text],
                                       pdict[:structure],
                                       ObjectCommon(pdict))
