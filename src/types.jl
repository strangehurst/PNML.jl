"Alias for Dict with expected value types for PNML intermediate representation."
const PnmlDict = Dict{Symbol, Any}
#const PnmlDict = Dict{Symbol, Union{Nothing,Dict,Vector,Symbol,AbstractString,Number}}
#const PnmlDict = Dict{Symbol, Union{Nothing,AbstractDict,Vector{AbstractDict},Symbol,AbstractString,Number}}

"""
$(TYPEDSIGNATURES)

Copy PnmlDict with keys removed when paired with value of `nothing`.
"""
function compress end

function compress(v::Vector{T}) where T <: AbstractDict
    #@show "compress vector $(length(v)) $T"
    map(compress, v)
end

function compress(d::T) where T <: AbstractDict
    #@show "compress $T"
    f = filter(x -> x.second !== nothing, d)
    for (k,v) in f
        if v  isa Union{T, Vector{T}}
            f[k] = compress(copy(v))
        end
    end
    f
end

function compress(a::T) where T
    @show "trying to compress unsupported $T"
    a
end

"""
$(TYPEDSIGNATURES)

In-place PnmlDict keys removed when they are paired with value of `nothing`.

"""
function compress!(v::Vector{T}) where T <: AbstractDict
    #@show "compress! vector $(length(v)) $T"
    foreach(compress!, v)
    v
end
function compress!(d::T) where T <: AbstractDict
    #@show "compress! $T"
    filter!(x->!isnothing(x.second), d)
    for (k,v) in d
        if v isa Union{T, Vector{T}}
            compress!(v)
        end
    end
    d
end
function compress!(a::T) where T
    @show "trying to compress! unsupported $T"
    a
end

"""
$(TYPEDEF)

Maybe of type `T` or nothing.
"""
const Maybe{T} = Union{T, Nothing}


#-------------------------------------------------------------------

