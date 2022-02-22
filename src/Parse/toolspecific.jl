"""
$(TYPEDSIGNATURES)

Return [`ToolInfo`](@ref) with tool & version attributes and content.

The content can be one or more well-formed xml elements.
Each are wrapped in a [`PnmlLabel`](@ref).
"""
function parse_toolspecific(node; kw...)
    nn = nodename(node)
    nn == "toolspecific" || error("element name wrong: $nn")
    EzXML.haskey(node, "tool") || throw(MalformedException("$(nn) missing tool attribute", node))
    EzXML.haskey(node, "version") || throw(MalformedException("$(nn) missing version attribute", node))
    
    d = PnmlDict(:tag    => Symbol(nn), 
                :tool    => node["tool"],
                :version => node["version"])
    
    d[:content] = PnmlLabel[] # Treat all top-level children as labels.
    foreach(elements(node)) do child
        #TODO: use parse_node here?
        #TODO: Specialize/verify on tool, version. User supplied?
        #TODO: Register additional tool specific parsers?
        push!(d[:content], PnmlLabel(unclaimed_element(child; kw...), child))
    end
    ToolInfo(d, node)
end
