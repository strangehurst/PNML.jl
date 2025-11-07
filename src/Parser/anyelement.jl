"""
$(TYPEDSIGNATURES)

Return [`AnyElement`](@ref) holding a well-formed XML node.
See [`ToolInfo`](@ref) for one intended use-case.
"""
function anyelement(node::XMLNode)::AnyElement
    AnyElement(xmldict(node)...)
end

"""
    xmldict(node::XMLNode) -> (tag, Union{DictType, String, SubString{String}})

Return tuple holding a well formed XML tree as parsed by `XMLDict.xml_dict`.
Symbols for attribute key, strings for element/child keys and strings for value/leaf.

`tag` is the name of the XML element that is "unparsed". It is the root of the tree.

See: [`anyelement`](@ref),
[`AnyElement`](@ref),[`PnmlLabel`](@ref), [`Labels.Structure`](@ref).
"""
function xmldict(node::XMLNode)
    xd = XMLDict.xml_dict(node, DictType; strip_text=true)
    return tuple(EzXML.nodename(node), xd::Union{DictType, String, SubString{String}})
    # empty dictionarys are a valid thing.
end
