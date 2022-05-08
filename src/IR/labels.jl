"""
$(TYPEDEF)
$(TYPEDFIELDS)

High-level pnml labels are expected to have <text> and <structure> elements.
This concrete type is for "unclaimed" labels in a high-level petri net.
"""    
struct HLLabel <: HLAnnotation
    text::Maybe{String}
    structure::Maybe{Structure}
    #TODO toolinfos
    #TODO graphics
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

Name(name::AbstractString = ""; graphics=nothing, tools=nothing) =
    Name(name, graphics, tools)

