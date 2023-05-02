#!
#! move to Core. Will split the HL* namespace into two
#!
"""
$(TYPEDEF)
$(TYPEDFIELDS)

High-level pnml labels are expected to have <text> and <structure> elements.
This concrete type is for "unclaimed" labels in a high-level petri net.

Some "claimed" `HLAnnotation` labels are [`Condition`](@ref),
[`Declaration`](@ref), [`HLMarking`](@ref), [`HLInscription`](@ref).
"""
struct HLLabel{PNTD} <: HLAnnotation
    text::Maybe{String}
    structure::Maybe{AnyElement}
    com::ObjectCommon
    xml::XMLNode
    #TODO validate in constructor: must have text or structure (depends on pntd?)
end

common(l::HLLabel) = i.com
