"""
$(TYPEDSIGNATURES)

Return [`ToolInfo`](@ref) with tool & version attributes and content.

The content can be one or more well-formed xml elements.
Each are wrapped in a [`PnmlLabel`](@ref).
"""
function parse_toolspecific(node, pntd, reg)
    nn = check_nodename(node, "toolspecific")
    EzXML.haskey(node, "tool") || throw(MalformedException("$nn missing tool attribute", node))
    EzXML.haskey(node, "version") || throw(MalformedException("$nn missing version attribute", node))

    tool    = node["tool"]
    version = node["version"]
    content = AnyElement[]

    for child in eachelement(node)
        #TODO: Specialize/verify on tool, version. User supplied?
        #TODO: Register additional tool specific parsers?
        push!(content, anyelement(child, pntd, reg))
    end
    ToolInfo(tool, version, content, node)
end
