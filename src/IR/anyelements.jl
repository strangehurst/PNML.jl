"""
Wrap `PnmlDict` holding well-formed XML.
"""
struct AnyElement
    dict
    xml
end

#AnyElement(dixt::PnmlDict, node::XMLNode) =    AnyElement(an)
