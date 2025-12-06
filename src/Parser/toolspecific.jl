
"""
$(TYPEDSIGNATURES)

Return [`ToolInfo`](@ref) with tool & version attributes and content.

The content can be one or more well-formed xml elements.
"""
function parse_toolspecific(node, pntd; parse_context::ParseContext,
                #!tp_vec = [ToolParser( "org.pnml.tool", "1.0", tokengraphics_content)])
                toolparser_vec = [])
    check_nodename(node, "toolspecific")
    tool    = attribute(node, "tool")
    version = attribute(node, "version")

    isempty(tool) && error("<toolspecific> tool attribute cannot be empty string")
    isempty(version) && error("<toolspecific> version attribute cannot be empty string")

    # Find parser for tool, version. #NB use of toolinfo mechanism.
    tool_parser = nothing
    if !isempty(toolparser_vec)
        tool_parser = first(Labels.get_toolinfo(toolparser_vec, tool, version))
        if !isnothing(tool_parser)
            tool_parser = tool_parser.func
        end
    end
    toolspecific_content = something(tool_parser, toolspecific_content_fallback)
    content = toolspecific_content(node, pntd) # Run ToolParser callable.
    #@show content
    return Labels.ToolInfo(tool, version, content, parse_context.ddict)
end

"""
Return `Vector{AnyElement}` for each well-formed element of a `<toolspecific> `node.`

#! Return an AbstractDict, likely a `DictType` as returned by `xmldict`.
"""
function toolspecific_content_fallback(node::XMLNode, pntd::PnmlType)
    anyelement(Symbol(EzXML.nodename(node)), node)
    #![anyelement(x) for x in EzXML.eachelement(node) if x !== nothing] # Empty is OK.
end
