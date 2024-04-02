"""
$(TYPEDSIGNATURES)

Return [`AnyElement`](@ref) holding a well-formed XML node.
See [`ToolInfo`](@ref) for one intended use-case.
"""
function anyelement(node::XMLNode, pntd::PnmlType, reg::PnmlIDRegistry)::AnyElement
    AnyElement(unparsed_tag(node)...)
end

"""
$(TYPEDSIGNATURES)

Return tuple of (tag, `XDVT`) holding well formed XML tree. `XMLDict`

The main use-case is to be wrapped in a [`PnmlLabel`](@ref), [`AnyElement`](@ref), et al.
"""
function unparsed_tag(node::XMLNode)
    tag = EzXML.nodename(node)
    xd = XMLDict.xml_dict(node, LittleDict{Union{Symbol, String}, Any}; strip_text=true)#::XVDT
    return (tag, xd)
    # empty dictionarys are a valid thing.
end

#-----------------------------------------------------------------------------

"""
$(TYPEDSIGNATURES)
Find first :text in vx and return its :content as string.
"""
function text_content end

function text_content(vx::Vector{XDVT2})
    isempty(vx) && throw(ArgumentError("empty `Vector{XDVT}` not expected"))
    text_content(first(vx))
end
function text_content(d::DictType)
    x = get(d, "text", nothing)
    isnothing(x) && throw(ArgumentError("missing <text> element in $(d)"))
    return x
end
text_content(s::Union{String,SubString{String}}) = s

"""
Find an XML attribute. XMLDict uses symbols as keys.
"""
function _attribute(vx::DictType, key::Symbol)
    x = get(vx, key, nothing)
    isnothing(x) && throw(ArgumentError("missing $key value"))
    isa(x, AbstractString)|| throw(ArgumentError("wrong type for attribute value, expected AbstractString got $(typeof(vx[key]))"))
    return x
 end
_attribute(s::Union{String,SubString{String}}, _::Symbol) = error(string("_attribute does not support ", s))
