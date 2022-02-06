"""
Return [`ToolInfo`](@ref) with tool & version attributes and content.

The content can be one or more well-formed xml elements.
Each are wrapped in a [`PnmlLabel`](@ref).

$(TYPEDSIGNATURES)
"""
function parse_toolspecific(node; kw...)
    nn = nodename(node)
    nn == "toolspecific" || error("element name wrong: $nn")
    EzXML.haskey(node, "tool") || throw(MalformedException("$(nn) missing tool attribute", node))
    EzXML.haskey(node, "version") || throw(MalformedException("$(nn) missing version attribute", node))
    
    d = PnmlDict(:tag    => Symbol(nn), 
                :tool    => node["tool"],
                :version => node["version"], 
                :xml     => includexml(node))
    # Treat all top-level children as labels.
    d[:content] = PnmlLabel[]
    foreach(elements(node)) do child
        push!(d[:content], PnmlLabel(unclaimed_element(child; kw...)))
    end
    #TODO: Specialize/verify on tool, version. User supplied?
    #TODO: Register additional tool specific parsers?
    ToolInfo(d)
end


