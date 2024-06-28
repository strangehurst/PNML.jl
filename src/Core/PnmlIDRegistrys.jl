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
struct PnmlIDRegistry{L <: Union{Nothing, Base.AbstractLock}}
    ids::Set{Symbol}
    lk::L
end

function Base.show(io::IO, registry::PnmlIDRegistry)
    print(io, nameof(typeof(registry)), " ", length(registry.ids), " ids: ", registry.ids)
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
    id ∈ registry.ids ? duplicate_id_action(id) : push!(registry.ids, id)
    return nothing
end
"""
$(TYPEDSIGNATURES)

Return `true` if `s` is registered in `reg`.
"""
function isregistered end

function isregistered(registry::PnmlIDRegistry{L}, id::Symbol)::Bool where {L <: Base.AbstractLock}
    @lock registry.lk id ∈ registry.ids
end
function isregistered(registry::PnmlIDRegistry{Nothing}, id::Symbol)::Bool
    id ∈ registry.ids
end

"""
$(TYPEDSIGNATURES)

Empty the set of id symbols. Use case is unit tests.
In normal use it should never be needed.
"""
function reset_reg! end
function reset_reg!(registry::PnmlIDRegistry{L}) where {L <: Base.AbstractLock}
    @lock registry.lk empty!(registry.ids)
    return nothing
end
function reset_reg!(registry::PnmlIDRegistry{Nothing})
    empty!(registry.ids)
    return nothing
end

function Base.isempty(registry::PnmlIDRegistry{L})::Bool where {L <: Base.AbstractLock}
    @lock registry.lk isempty(registry.ids)
end

function Base.isempty(registry::PnmlIDRegistry{Nothing})::Bool
    isempty(registry.ids)
end

end # module PnmlIDRegistrys
