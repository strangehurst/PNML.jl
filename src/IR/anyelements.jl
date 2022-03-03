"""
Wrap `PnmlDict` holding well-formed XML. 
See [`ToolInfo`](@ref) and [`PnmlLabel`](@ref).
"""
struct AnyElement
    dict::PnmlDict
    xml::XMLNode
end

#AnyElement(dixt::PnmlDict, node::XMLNode) =    AnyElement(an)
