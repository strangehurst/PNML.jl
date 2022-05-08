"""
$(TYPEDEF)
$(TYPEDFIELDS)

ToolInfo holds a <toolspecific> tag.

It wraps a vector of well formed elements parsed into [`AnyElement`](@ref)s.
for use by anything that understands toolname, version toolspecifics.
"""
@auto_hash_equals struct ToolInfo
    toolname::String
    version::String
    infos::Vector{AnyElement} #TODO specialize infos.
    xml::XMLNode
end

name(ti::ToolInfo) = ti.toolname
version(ti::ToolInfo) = ti.version
infos(ti::ToolInfo) = ti.infos

xmlnode(ti::ToolInfo) = ti.xml

###############################################################################

"""
$(TYPEDEF)
$(TYPEDFIELDS)

TokenGraphics is <toolspecific> content.
Combines the <tokengraphics> and <tokenposition> elements.
"""
struct TokenGraphics <: AbstractPnmlTool
    positions::Vector{Coordinate} #TODO: uses abstract type
end

# Empty TokenGraphics is allowed in spec.
TokenGraphics() = TokenGraphics(Coordinate[])

