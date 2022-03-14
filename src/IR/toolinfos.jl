"""
$(TYPEDEF)
$(TYPEDFIELDS)

ToolInfo holds a <toolspecific> tag.

It wraps a vector of well formed elements parsed into [`AnyElement`](@ref)s.
for use by anything that understands toolname, version toolspecifics.
"""
struct ToolInfo
    toolname::String
    version::String
    infos::Vector{AnyElement} #TODO specialize infos.
    xml::XMLNode
end

function ToolInfo(d::PnmlDict, xml::XMLNode)
    ToolInfo(d[:tool], d[:version], d[:content], xml)
end
convert(::Type{Maybe{ToolInfo}}, d::PnmlDict) = ToolInfo(d)

has_xml(ti::ToolInfo) = true
xmlnode(ti::ToolInfo) = ti.xml

infos(ti::ToolInfo) = ti.infos

###############################################################################

"""
$(TYPEDEF)
$(TYPEDFIELDS)

TokenGraphics is <toolspecific> content and is wrapped by a [`ToolInfo`](@ref).
It combines the <tokengraphics> and <tokenposition> elements.
"""
struct TokenGraphics <: AbstractPnmlTool
    positions::Vector{Coordinate} #TODO: uses abstract type
end

# Empty TokenGraphics is allowed in spec.
TokenGraphics() = TokenGraphics(Coordinate[])

