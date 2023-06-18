"""
$(TYPEDEF)
$(TYPEDFIELDS)

Name is for display, possibly in a tool specific way.
"""
@kwdef struct Name <: Annotation
    text::String = ""
    graphics::Maybe{Graphics} = nothing
    tools::Vector{ToolInfo}  = ToolInfo[] #! make ToolInfo concrete?
end
