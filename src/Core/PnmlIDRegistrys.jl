"""
Petri Net Markup Language identifier registry.
"""
module PnmlIDRegistrys
using Preferences
using DocStringExtensions

export PnmlIDRegistry, register_id!, isregistered, reset_reg!

"""
Holds a set of PNML ID symbols and , optionally, a lock to allow safe reentrancy.

$(TYPEDEF)
"""
@kwdef struct PnmlIDRegistry{L <: Union{Nothing, Base.AbstractLock}}
    idset::IdSet{Symbol} = IdSet{Symbol}
    lk::L
    #lk2::Base.Lockable(idset::IdSet{Symbol}())
end

function Base.show(io::IO, registry::PnmlIDRegistry)
    print(io, nameof(typeof(registry)), " ", length(registry.idset), " ids: ", values(registry.idset))
end

duplicate_id_action(id::Symbol)  = error("ID already registered: $id")

"""
$(TYPEDSIGNATURES)

Register `id` symbol and return the symbol.
"""
function register_id! end
function register_id!(registry::PnmlIDRegistry{L}, id::Symbol)::Symbol where {L <: Base.AbstractLock}
    @lock registry.lk _reg!(registry, id)
    return id
end
function register_id!(registry::PnmlIDRegistry{Nothing}, id::Symbol)::Symbol
    _reg!(registry, id)
    return id
end

_reg!(registry, id) = begin
    id ∈ registry.idset ? duplicate_id_action(id) : push!(registry.idset, id)
    return nothing
end
"""
$(TYPEDSIGNATURES)

Return `true` if `s` is registered in `reg`.
"""
function isregistered end

function isregistered(registry::PnmlIDRegistry{L}, id::Symbol)::Bool where {L <: Base.AbstractLock}
    @lock registry.lk id ∈ registry.idset
end
function isregistered(registry::PnmlIDRegistry{Nothing}, id::Symbol)::Bool
    id ∈ registry.idset
end

"""
$(TYPEDSIGNATURES)

Empty the set of id symbols. Use case is unit tests.
"""
function reset_reg! end
function reset_reg!(registry::PnmlIDRegistry{L}) where {L <: Base.AbstractLock}
    @lock registry.lk empty!(registry.idset)
    return nothing
end
function reset_reg!(registry::PnmlIDRegistry{Nothing})
    empty!(registry.idset)
    return nothing
end

function Base.isempty(registry::PnmlIDRegistry{L})::Bool where {L <: Base.AbstractLock}
    @lock registry.lk isempty(registry.idset)
end

function Base.isempty(registry::PnmlIDRegistry{Nothing})::Bool
    isempty(registry.idset)
end

end # module PnmlIDRegistrys
