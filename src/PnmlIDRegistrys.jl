"""
Petri Net Markup Language identifier registry.
"""
module PnmlIDRegistrys
using Preferences
using DocStringExtensions

export PnmlIDRegistry, register_id!, isregistered
public reset_reg!
using Base: Base.IdSet
import Base: eltype

"""
Holds a set of PNML ID symbols and, optionally, a lock to allow safe reentrancy.

$(TYPEDEF)
"""
@kwdef struct PnmlIDRegistry
    idset::IdSet{Symbol} = IdSet{Symbol}()
    lk::ReentrantLock = ReentrantLock()
end

function Base.show(io::IO, reg::PnmlIDRegistry)
    print(io, nameof(typeof(reg)), "(", collect(values(reg)), ")")
end

duplicate_id_action(id::Symbol)  = error("ID already registered: $id")

"""
$(TYPEDSIGNATURES)

Register `id` symbol and return the symbol.
"""
function register_id!(registry::PnmlIDRegistry, id::Symbol)
    @lock registry.lk _reg!(registry, id)
    return id
end

_reg!(registry, id) = begin
    #println("register id ", repr(id), " in reg ", objectid(registry)) #! debug
    id ∈ registry.idset ? duplicate_id_action(id) : push!(registry.idset, id)
    return registry
end

"""
$(TYPEDSIGNATURES)

Return `true` if `id` is registered in `registry`.
"""
function isregistered(registry::PnmlIDRegistry, id::Symbol)
    @lock registry.lk id ∈ registry.idset
end

"""
$(TYPEDSIGNATURES)

Empty the set of id symbols. Use case is unit tests.
"""
function reset_reg!(registry::PnmlIDRegistry)
    #println("reset PnmlIDRegistry ", objectid(registry)) #! debug
    @lock registry.lk empty!(registry.idset)
    return registry
end

function Base.isempty(registry::PnmlIDRegistry)
    @lock registry.lk isempty(registry.idset)::Bool
end

function Base.length(registry::PnmlIDRegistry)
    @lock registry.lk length(registry.idset)
end

function Base.values(registry::PnmlIDRegistry)
    @lock registry.lk values(registry.idset)
end

end # module PnmlIDRegistrys
