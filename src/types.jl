"""
Alias for Dict with Symbol key.
Allows code to have semantic information in type names, better searchability.

$(TYPEDEF)
"""
const PnmlDict = Dict{Symbol, Any}

"""
Alias for union of type `T` or `nothing`.

$(TYPEDEF)
"""
const Maybe{T} = Union{T, Nothing}
