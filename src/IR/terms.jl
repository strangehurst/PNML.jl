"""
$(TYPEDEF)
$(TYPEDFIELDS)

Part of the many-sorted algebra attached to nodes on a Petri Net Graph.

 ast variants:
  - variable
  - operator
"""
struct Term #TODO 
    dict::PnmlDict #TODO AnyElement for bring-up? What should be here?
    #TODO xml
end

Term() = Term(PnmlDict())
convert(::Type{Maybe{Term}}, pdict::PnmlDict) = Term(pdict)
