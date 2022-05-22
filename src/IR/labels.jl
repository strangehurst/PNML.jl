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

#------------------------------------------------------------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Name is for display, possibly in a tool specific way.
"""
struct Name <: AbstractLabel
    text::String
    graphics::Maybe{Graphics}
    tools::Maybe{Vector{ToolInfo}}
end

Name(; text::AbstractString = "", graphics=nothing, tools=nothing) =
    Name(text, graphics, tools)

