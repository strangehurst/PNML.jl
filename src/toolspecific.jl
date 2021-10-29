
"""
$(SIGNATURES)

Return PnmlDict with tag name, tool & version attributes and content parsed.
Anyone that can parse the `:content` may specialize on tool & version.

The content can be any well-formed xml. We use our usual parsing mechanism,
which can be enhanced if someone makes a good case.
"""
function parse_toolspecific(node; kwargs...)
    nn = nodename(node)
    nn == "toolspecific" || error("element name wrong: $nn")
    haskey(node, "tool") || throw(MalformedException("$(nn) missing tool attribute", node))
    haskey(node,"version") || throw(MalformedException("$(nn) missing version attribute", node))

    d = PnmlDict(:tag=>Symbol(nn), :tool=>node["tool"], :version=>node["version"],
                 :content=>parse_node.(elements(node); kwargs...),
                 :xml=>includexml(node))
    
    #TODO: Specialize/verify on tool, version. User supplied?
    #TODO: Register additional tool specific parsers?
    d
end

