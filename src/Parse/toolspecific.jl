"""
$(TYPEDSIGNATURES)

Return [`ToolInfo`](@ref) with tool & version attributes and content.

The content can be one or more well-formed xml elements.
Each are wrapped in a [`PnmlLabel`](@ref).
"""
function parse_toolspecific(node, pntd, reg)
    nn = check_nodename(node, "toolspecific")
    EzXML.haskey(node, "tool") || throw(MalformedException(lazy"$nn missing tool attribute"))
    EzXML.haskey(node, "version") || throw(MalformedException(lazy"$nn missing version attribute"))

    tool    = node["tool"]
    version = node["version"]
    #CONFIG.verbose &&
    println("$nn $tool $version")

    if tool == "org.pnml.tool" && version == "1.0"
        child = EzXML.firstelement(node)
        if nodename(child) == "tokengraphics"
            tg = parse_tokengraphics(child, pntd, reg)
            #println("tokengraphics"); dump(tg)
            return ToolInfo(tool, version, tg, node)
        else
            ae = anyelement(child, pntd, reg)
            @warn "unexpected anyelement toolinfo for $tool $version" dump(ae)
            return ToolInfo(tool, version, anyelement(child, pntd, reg), node)
        end
    else
        content = AnyElement[]
        for child in eachelement(node)
            #TODO: Specialize/verify on tool, version. User supplied?
            #TODO: Register additional tool specific parsers?
            push!(content, anyelement(child, pntd, reg))
        end
        isempty(content)
        return ToolInfo(tool, version, content, node)
    end
end
