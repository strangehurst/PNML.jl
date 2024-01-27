"""
Petri Net Markup Language identifier registry.
"""
module PnmlIDRegistrys
using Preferences
using DocStringExtensions

export PnmlIDRegistry, register_id!, isregistered, reset!

"""
Holds a set of pnml id symbols and a lock to allow safe reentrancy.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct PnmlIDRegistry{L}
    ids::Set{Symbol}
    lk::L
end

function Base.show(io::IO, idregistry::PnmlIDRegistry)
    print(io, nameof(typeof(idregistry)), " ", length(idregistry.ids), " ids: ", idregistry.ids)
end

duplicate_id_action(id::Symbol)  = @warn("ID already registered: $id")

"""
$(TYPEDSIGNATURES)

Register `id` symbol and return the symbol.
"""
function register_id!(idregistry::PnmlIDRegistry, s::AbstractString)
    register_id!(idregistry, Symbol(s))
end

function register_id!(idregistry::PnmlIDRegistry{L}, id::Symbol)::Symbol where {L <: Base.AbstractLock}
    @lock idregistry.lk _reg(idregistry, id)
    return id
end

function register_id!(idregistry::PnmlIDRegistry{Nothing}, id::Symbol)::Symbol
    _reg(idregistry, id)
    return id
end

_reg(reg, id) = begin
    id ∈ reg.ids ? duplicate_id_action(id) : push!(reg.ids, id)
    return nothing
end
"""
$(TYPEDSIGNATURES)

Return `true` if `s` is registered in `reg`.
"""
isregistered(reg::PnmlIDRegistry, s::AbstractString) = isregistered(reg, Symbol(s))

function isregistered(idregistry::PnmlIDRegistry{L}, id::Symbol)::Bool where {L <: Base.AbstractLock}
    @lock idregistry.lk id ∈ idregistry.ids
end

function isregistered(idregistry::PnmlIDRegistry{Nothing}, id::Symbol)::Bool
    id ∈ idregistry.ids
end

"""
$(TYPEDSIGNATURES)

Empty the set of id symbols. Use case is unit tests.
In normal use it should never be needed.
"""
function reset! end

function reset!(idregistry::PnmlIDRegistry{L}) where {L <: Base.AbstractLock}
    @lock idregistry.lk empty!(idregistry.ids)
end

function reset!(idregistry::PnmlIDRegistry{Nothing})
    empty!(idregistry.ids)
end

function Base.isempty(idregistry::PnmlIDRegistry{L})::Bool where {L <: Base.AbstractLock}
    @lock idregistry.lk isempty(idregistry.ids)
end

function Base.isempty(idregistry::PnmlIDRegistry{Nothing})::Bool
    isempty(idregistry.ids)
end

end # module PnmlIDRegistrys
