
"""
$(TYPEDSIGNATURES)

Return [`ToolInfo`](@ref) with tool & version attributes and content.

The content can be one or more well-formed xml elements.
"""
function parse_toolspecific(node, pntd; parse_context::ParseContext,
            tp_vec = [ToolParser( "org.pnml.tool", "1.0", tokengraphics_content)])
    check_nodename(node, "toolspecific")
    tool    = attribute(node, "tool")
    version = attribute(node, "version")

    # Find parser for tool, version
    tool_parser = Labels.get_toolinfo(tp_vec, tool, version)
    if !isnothing(tool_parser)
        tool_parser = tool_parser.func
    end
    toolspecific_content = something(tool_parser, toolspecific_content_fallback)

    content = toolspecific_content(node, pntd) # Run ToolParser callable.
    return Labels.ToolInfo(tool, version, content, parse_context.ddict)
end

"""
Return `Vector{AnyElement}` for each well-formed element of a `<toolspecific> `node.`
"""
function toolspecific_content_fallback(node::XMLNode, pntd::PnmlType)
    [anyelement(x) for x in EzXML.eachelement(node) if x !== nothing] # Empty is OK.
end
