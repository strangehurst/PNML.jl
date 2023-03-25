"""
$(TYPEDEF)
$(TYPEDFIELDS)

Wrap `PnmlDict` holding well-formed XML.

See [`ToolInfo`](@ref) and [`PnmlLabel`](@ref).
"""
@auto_hash_equals struct AnyElement
    tag::Symbol
    dict::PnmlDict #! make into tuple
    xml::XMLNode
end

AnyElement(p::Pair{Symbol,PnmlDict}, xml::XMLNode) = AnyElement(p.first, p.second, xml)

tag(a::AnyElement) = a.tag
dict(a::AnyElement) = a.dict  #! make into tuple
xmlnode(a::AnyElement) = a.xml
