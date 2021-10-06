#TODO; replace Any by more specific types
#const PnmlDict = Dict{Symbol, Union{Nothing,Any}}
const PnmlDict = Dict{Symbol, Union{Nothing,Dict,Vector,NamedTuple,Symbol,AbstractString,Number}}

"""
Maybe of type `T` or nothing.
"""
const Maybe{T} = Union{T, Nothing}

