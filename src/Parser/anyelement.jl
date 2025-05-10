"""
$(TYPEDSIGNATURES)

Return [`AnyElement`](@ref) holding a well-formed XML node.
See [`ToolInfo`](@ref) for one intended use-case.
"""
function anyelement(node::XMLNode, pntd::PnmlType)::AnyElement
    AnyElement(unparsed_tag(node)...)
end

"""
$(TYPEDSIGNATURES)

Return tuple of (tag, `XDVT`) holding well formed XML as parsed by `XMLDict`.

The main use-case is to be wrapped in a [`PnmlLabel`](@ref), [`AnyElement`](@ref),
or [`Labels.Structure`](@ref).
"""
function unparsed_tag(node::XMLNode)
    tag = EzXML.nodename(node)
    #!xd = XMLDict.xml_dict(node, LittleDict{Union{Symbol, String}, Any}; strip_text=true)
    xd = XMLDict.xml_dict(node, DictType; strip_text=true)
    return tuple(tag, xd)
    # empty dictionarys are a valid thing.
end
