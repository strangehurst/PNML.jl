"""
$(TYPEDEF)
$(TYPEDFIELDS)

Hold well-formed XML in a Vector{[`AnyXmlNode`](@ref)}. See also [`ToolInfo`](@ref) and [`PnmlLabel`](@ref).
"""
@auto_hash_equals struct AnyElement
    tag::Symbol # XML tag
    elements::Vector{AnyXmlNode}
    xml::XMLNode
end

AnyElement(p::Pair{Symbol, Vector{AnyXmlNode}}, xml::XMLNode) = AnyElement(p.first, p.second, xml)

tag(a::AnyElement) = a.tag
elements(a::AnyElement) = a.elements
xmlnode(a::AnyElement) = a.xml
