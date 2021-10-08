
"""
Return tuple with tag name, tool & version attributes and xml node.
Anyone that can parse the nodecontents may specialize on tool & version.
"""
function parse_toolspecific(node; kwargs...)
    nn = nodename(node)
    nn == "toolspecific" || error("parse_toolspecific element name wrong: $nn")
    haskey(node, "tool") || throw(MalformedException("$(nn) missing tool attribute", node))
    haskey(node,"version") || throw(MalformedException("$(nn) missing version attribute", node))

    d = PnmlDict(:tag=>Symbol(nn), :tool=>node["tool"], :version=>node["version"],
                 :content=>parse_node.(elements(node); kwargs...),
                 :xml=>includexml(node))
    
    #TODO: Specialize/verify on tool, version. User supplied?
    #TODO: Register additional tool specific parsers?
    d
end

