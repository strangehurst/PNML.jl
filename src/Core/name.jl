"""
$(TYPEDEF)
$(TYPEDFIELDS)

Name is for display, possibly in a tool specific way.
"""
struct Name <: Annotation
    text::String
    #pntd
    graphics::Maybe{Graphics}
    tools::Maybe{Vector{ToolInfo}}
end
