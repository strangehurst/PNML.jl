
"""
$(TYPEDSIGNATURES)

Return [`ToolInfo`](@ref) with tool & version attributes and content.

The content can be one or more well-formed xml elements.
"""
function parse_toolspecific(node, pntd;
            tp_vec = [ToolParser( "org.pnml.tool", "1.0", tokengraphics_content)])
    nn = check_nodename(node, "toolspecific")
    tool    = attribute(node, "tool")
    version = attribute(node, "version")

    # Find parser for tool,version pair from (ScopedValue?).
    @show tp_vec
    @show tool_parser = Labels.get_toolinfo(tp_vec, tool, version)
    if !isnothing(tool_parser)
        tool_parser = tool_parser.func
    end
       @show toolspecific_content = something(tool_parser, toolspecific_content_fallback)
    # Handle all other toolinfos as AnyElement (holding well-formed XML).
    @show content = toolspecific_content(node, pntd)
    return Labels.ToolInfo(tool, version, content)
end

"""
Return `Vector{AnyElement}` for each well-formed element of a `<toolspecific> `node.`
"""
function toolspecific_content_fallback(node::XMLNode, pntd::PnmlType)
    content = AnyElement[]
    for child in EzXML.eachelement(node)
        push!(content, anyelement(child, pntd))
    end
    return content # Empty is allowed.
end
