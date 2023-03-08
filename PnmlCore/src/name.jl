"""
$(TYPEDEF)
$(TYPEDFIELDS)

Name is for display, possibly in a tool specific way.
"""
struct Name <: Annotation
    text::String
    graphics::Maybe{Graphics}
    tools::Maybe{Vector{ToolInfo}}
end

Name(; text::AbstractString = "", graphics=nothing, tools=nothing) =
    Name(text, graphics, tools)
