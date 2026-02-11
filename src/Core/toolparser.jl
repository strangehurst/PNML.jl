# ToolParser
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Holds a parser callable for a `<toolspecific>` tag's well-formed contents.

Will be in an iteratable collection that maps tool name & version to a parser callable.
See `toolspecific_content_fallback(node, pntd)`.
"""
@auto_hash_equals struct ToolParser{T <: Base.Callable}
    toolname::String
    version::String
    func::T
end

PNML.name(ti::ToolParser) = ti.toolname
version(ti::ToolParser) = ti.version

"Return callable parser of a ToolInfo."
func(ti::ToolParser) = ti.func
