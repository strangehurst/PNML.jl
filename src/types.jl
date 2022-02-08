"""
Alias for Dict with Symbol as key.

$(TYPEDEF)
"""
const PnmlDict = Dict{Symbol, Any}

"""
Alias for union of type `T` or `nothing`.

$(TYPEDEF)
"""
const Maybe{T} = Union{T, Nothing}
