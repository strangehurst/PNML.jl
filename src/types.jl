const PnmlDict = Dict{Symbol, Union{Nothing,Dict,Vector,NamedTuple,Symbol,AbstractString,Number}}

"""
    compress(v::Vector{PnmlDict})
    compress(d::PnmlDict)

Copy PnmlDict with keys removed when they are paired with value of `nothing`.

"""
function compress end
function compress(v::Vector{T}) where T <: AbstractDict
    #@show "compress vector $(length(v)) $T"
    v2 = map(compress, v)
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
    compress(v::Vector{PnmlDict})
    compress(d::PnmlDict)

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
    @show "trying to compress unsupported $T"
    a
end

"""
Maybe of type `T` or nothing.
"""
const Maybe{T} = Union{T, Nothing}


#-------------------------------------------------------------------

