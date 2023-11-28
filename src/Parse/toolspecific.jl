"""
$(TYPEDSIGNATURES)

Return [`ToolInfo`](@ref) with tool & version attributes and content.

The content can be one or more well-formed xml elements.
Each are wrapped in a [`PnmlLabel`](@ref).
"""
function parse_toolspecific(node, pntd, reg)
    nn = check_nodename(node, "toolspecific")
    EzXML.haskey(node, "tool") || throw(MalformedException("$nn missing tool attribute"))
    EzXML.haskey(node, "version") || throw(MalformedException("$nn missing version attribute"))

    tool    = node["tool"]
    version = node["version"]
    CONFIG.verbose && println("$nn $tool $version")

    # # Handle toolinfos that we recognize.
    # # Most will assume only one child element and ignore the rest.
    # if tool == "org.pnml.tool" && version == "1.0"
    #     child = EzXML.firstelement(node)
    #     tag = EzXML.nodename(child)
    #     if tag == "tokengraphics"
    #         tg = parse_tokengraphics(child, pntd, reg)
    #         #println("tokengraphics"); dump(tg)
    #         return ToolInfo(tool, version, tg)
    #     end
    # end
    #TODO: Register additional tool specific parsers?

    # Handle all other toolinfos as AnyElement (holding well-formed XML).
    content = AnyElement[]
    for child in EzXML.eachelement(node)
        push!(content, anyelement(child, pntd, reg))
    end
    # Empty is allowed. Do we
    #TODO isempty(content) && @info "<toolspecific> $tool $version missing content"
    return ToolInfo(tool, version, content)
end
