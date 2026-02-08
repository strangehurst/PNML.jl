
"""
$(TYPEDSIGNATURES)

Return [`ToolInfo`](@ref) with tool & version attributes and content.

The content can be one or more well-formed xml elements.
"""
function parse_toolspecific(node, pntd; net::AbstractPnmlNet)
    check_nodename(node, "toolspecific")
    tool    = attribute(node, "tool")
    version = attribute(node, "version")

    isempty(tool) && error("<toolspecific> tool attribute cannot be empty string")
    isempty(version) && error("<toolspecific> version attribute cannot be empty string")

    # Find parser for tool, version.
    tool_parser = if haskey(net.toolparser, tool=>version)
        @show net.toolparser[tool=>version]
    else
        toolspecific_content_fallback
    end
    content = tool_parser(node, pntd) # Run ToolParser callable.
    return Labels.ToolInfo(tool, version, content, net)
end

"""
Return `Vector{AnyElement}` for each well-formed element of a `<toolspecific> `node.`

#! Return an AbstractDict, likely a `XmlDictType` as returned by `xmldict`.
"""
function toolspecific_content_fallback(node::XMLNode, pntd::PnmlType)
    anyelement(Symbol(EzXML.nodename(node)), node)
    #![anyelement(x) for x in EzXML.eachelement(node) if x !== nothing] # Empty is OK.
end
