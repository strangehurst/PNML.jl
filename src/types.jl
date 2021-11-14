"""
$(TYPEDEF)

Alias for Dict with Symbol key.
"""
const PnmlDict = Dict{Symbol, Any}

"""
$(TYPEDSIGNATURES)

Copy PnmlDict with keys removed when paired with value of `nothing`.
Return the copy.
"""
function compress end

function compress(v::Vector{T}) where T <: PnmlDict
    map(compress, v)
end

function compress(d::T) where T <: PnmlDict
    f = filter(x -> x.second !== nothing, d)
    for (k,v) in f
        if v  isa Union{T, Vector{T}}
            f[k] = compress(copy(v))
        end
    end
    f
end

function compress(a::T) where T
    @warn "trying to compress unsupported $T"
    a
end

"""
$(TYPEDSIGNATURES)

PnmlDict keys removed when they are paired with value of `nothing`.
Return modified dict.
"""
function compress!(v::Vector{T}) where T <: PnmlDict
    foreach(compress!, v)
    v
end

function compress!(d::T) where T <: PnmlDict
    filter!(x->!isnothing(x.second), d)
    for (k,v) in d
        if v isa Union{T, Vector{T}}
            compress!(v)
        end
    end
    d
end

function compress!(a::T) where T
    @warn "trying to compress! unsupported $T"
    a
end


"""
$(TYPEDEF)

Union of type `T` or nothing.
"""
const Maybe{T} = Union{T, Nothing}

