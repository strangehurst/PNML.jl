"""
Alias for Dict with Symbol key.
Allows code to have semantic information in type names, better searchability.

$(TYPEDEF)
"""
const PnmlDict = Dict{Symbol, Any}


"""
Return pnml id symbol, if argument has one, otherwise return `nothing`.

---
$(TYPEDSIGNATURES)

$(METHODLIST)
"""
function pid end
pid(::Any) = nothing
pid(node::PnmlDict)::Symbol = node[:id]

"""
Return tag symbol, if argument has one, otherwise `nothing`.

---
$(TYPEDSIGNATURES)

$(METHODLIST)
"""
function tag end
tag(::Any) = nothing
tag(pdict::PnmlDict)::Symbol = pdict[:tag]


"""
Return xml node field of `d` or `nothing`.

---
$(TYPEDSIGNATURES)

$(METHODLIST)
"""
function xmlnode end
xmlnode(::Any) = nothing
xmlnode(pdict::PnmlDict) = pdict[:xml]




"""
Alias for union of type `T` or `nothing`.

$(TYPEDEF)
"""
const Maybe{T} = Union{T, Nothing}
