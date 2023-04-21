"""
$(TYPEDEF)
$(TYPEDFIELDS)

Wrap `NamedTuple` holding well-formed XML. See also [`ToolInfo`](@ref) and [`PnmlLabel`](@ref).
"""
@auto_hash_equals struct AnyElement
    tag::Symbol
    dict::NamedTuple
    xml::XMLNode
end

AnyElement(p::Pair{Symbol,<:NamedTuple}, xml::XMLNode) = AnyElement(p.first, p.second, xml)
AnyElement(p::Pair{Symbol,Vector{Pair{Symbol,Any}}}, xml::XMLNode) = AnyElement(p.first, namedtuple(p.second), xml)

tag(a::AnyElement) = a.tag
dict(a::AnyElement) = a.dict  #! tuple
xmlnode(a::AnyElement) = a.xml
