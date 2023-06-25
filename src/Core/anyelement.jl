"""
$(TYPEDEF)
$(TYPEDFIELDS)

Wrap `NamedTuple` holding well-formed XML. See also [`ToolInfo`](@ref) and [`PnmlLabel`](@ref).
"""
@auto_hash_equals struct AnyElement #{T <: NamedTuple}
    tag::Symbol # XML tag
    elements::Vector{AnyXmlNode}
    xml::XMLNode
end

AnyElement(p::Pair{Symbol, Vector{AnyXmlNode}}, xml::XMLNode) = AnyElement(p.first, p.second, xml)

tag(a::AnyElement) = a.tag
elements(a::AnyElement) = a.elements
xmlnode(a::AnyElement) = a.xml
