"""
$(TYPEDSIGNATURES)

Return [`ToolInfo`](@ref) with tool & version attributes and content.

The content can be one or more well-formed xml elements.
Each are wrapped in a [`PnmlLabel`](@ref).
"""
function parse_toolspecific(node; kw...)
    nn = nodename(node)
    nn == "toolspecific" || error("element name wrong: $nn")
    haskey(node, "tool") || throw(MalformedException("$(nn) missing tool attribute", node))
    haskey(node,"version") || throw(MalformedException("$(nn) missing version attribute", node))
    
    d = PnmlDict(:tag=>Symbol(nn), :tool=>node["tool"], :version=>node["version"],
                 :content=>unclaimed_element.(elements(node); kw...),
                 :xml=>includexml(node))
    # unclaimed_elements 
    #TODO: Specialize/verify on tool, version. User supplied?
    #TODO: Register additional tool specific parsers?
    ToolInfo(d)
end

