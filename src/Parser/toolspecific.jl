
"""
$(TYPEDSIGNATURES)

Return [`ToolInfo`](@ref) with tool & version attributes and content.

The content can be one or more well-formed xml elements.
"""
function parse_toolspecific(node, pntd)
    nn = check_nodename(node, "toolspecific")
    tool    = attribute(node, "tool")
    version = attribute(node, "version")

    # Find parser for tool,version pair from (ScopedValue?).
    @show tool_parser = Labels.get_toolinfo(PNML.TOOLSPECIFIC_PARSERS, tool, version)

    # # Handle toolinfos that we recognize.
    # # Most will assume only one child element and ignore the rest.
    # if tool == "org.pnml.tool" && version == "1.0"
    #     child = EzXML.firstelement(node)
    #     tag = EzXML.nodename(child)
    #     if tag == "tokengraphics"
    #         tg = parse_tokengraphics(child, pntd)
    #         #println("tokengraphics"); dump(tg)
    #         return ToolInfo(tool, version, tg)
    #     end
    # end
    #TODO: Register additional tool specific parsers?
    toolspecific_content = something(tool_parser, toolspecific_content_fallback)
    # Handle all other toolinfos as AnyElement (holding well-formed XML).
    content = toolspecific_content(node, pntd)
    return ToolInfo(tool, version, content)
end

function toolspecific_content_fallback(node, pntd)
    content = AnyElement[]
    for child in EzXML.eachelement(node)
        push!(content, anyelement(child, pntd))
    end
    return content # Empty is allowed.
end
