"""
$(TYPEDEF)
$(TYPEDFIELDS)

High-level pnml labels are expected to have <text> and <structure> elements.
This concrete type is for "unclaimed" labels in a high-level petri net.
Some "claimed" `HLAnnotation` labels are [`Condition`](@ref), 
[`Declaration`](@ref), [`HLMarking`](@ref), [`HLInscription`](@ref).
"""    
struct HLLabel <: HLAnnotation
    text::Maybe{String}
    structure::Maybe{Structure}
    com::ObjectCommon    #TODO labels, toolinfos, graphics
    xml::XMLNode
    #TODO validate in constructor: must have text or structure
end