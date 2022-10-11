"""
$(TYPEDEF)
$(TYPEDFIELDS)

Wrap `PnmlDict` holding well-formed XML.

See [`ToolInfo`](@ref) and [`PnmlLabel`](@ref).
"""
@auto_hash_equals struct AnyElement
    tag::Symbol
    dict::PnmlDict
    xml::XMLNode
end

AnyElement(p::Pair{Symbol,PnmlDict}, xml::XMLNode) = AnyElement(p.first, p.second, xml)

tag(a::AnyElement) = a.tag
dict(a::AnyElement) = a.dict
xmlnode(a::AnyElement) = a.xml

pid(object::PnmlObject) = object.id
has_name(o::T) where {T <: PnmlObject} = o.name !== nothing
name(o::T) where {T <: PnmlObject} = has_name(o) ? o.name.text : ""
has_labels(o::T) where {T <: PnmlObject} = has_labels(o.com)
labels(o::T) where {T <: PnmlObject} = labels(o.com)

has_label(o::T, tagvalue::Symbol) where {T <: PnmlObject} =
    if has_labels(o)
        l = labels(o)
        l !== nothing ? has_label(l, tagvalue) : false
    else
        false
    end
get_label(o::T, tagvalue::Symbol) where {T <: PnmlObject} =
    if has_labels(o)
        l = labels(o)
        l !== nothing ? get_label(l, tagvalue) : nothing
    else
        nothing
    end

has_tools(o::T) where {T <: PnmlObject} = has_tools(o.com) && !isnothing(tools(o.com))
tools(o::T) where {T <: PnmlObject} = tools(o.com)
#TODO has_tool, get_tool
