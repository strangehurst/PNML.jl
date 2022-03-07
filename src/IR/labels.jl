"""
"""    
struct HLLabel <: AbstractLabel #TODO make abstract?
    text::Maybe{String}
    structure::Maybe{Structure}
    #TODO toolinfos
    #TODO graphics
    xml::XMLNode
end

# interface methods
has_text(label::HLLabel) = !isnothing(label.text)
text(label::HLLabel) = label.text
has_structure(label::HLLabel) = !isnothing(label.structure)
structure(label::HLLabel) = label.structure

#------------------------------------------------------------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Name is for display, possibly in a tool specific way.
"""
struct Name <: AbstractLabel
    text::String
    graphics::Maybe{Graphics} #TODO check relaxng schema.
    tools::Maybe{Vector{ToolInfo}}
end

Name(name::AbstractString = ""; graphics=nothing, tools=nothing) =
    Name(name, graphics, tools)

