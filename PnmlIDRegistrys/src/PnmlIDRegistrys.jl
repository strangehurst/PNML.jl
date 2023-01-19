"""
Petri Net Markup Language identifier registry.
"""
module PnmlIDRegistrys

using DocStringExtensions
using Base: @kwdef
export PnmlIDRegistry, register_id!, isregistered_id

"""
Holds a set of pnml id symbols and a lock to allow safe reentrancy.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
@kwdef struct PnmlIDRegistry
    ids::Set{Symbol}    = Set{Symbol}()
    lk::ReentrantLock   = ReentrantLock()
    duplicate::Function = duplicate_id_warn
end

#PnmlIDRegistry() = PnmlIDRegistry(Set{Symbol}(), ReentrantLock(), duplicate_id_warn)

"TODO rename all current uses?"
const IDRegistry = PnmlIDRegistry #! TODO rename

function Base.show(io::IO, reg::PnmlIDRegistry)
    print(io, typeof(reg), " ", length(reg.ids),
        " ids: ", reg.ids, " duplicate action: ", nameof(reg.duplicate))
end

"""
$(TYPEDSIGNATURES)

Duplicated pnml id `id` has been detected.
"""
function duplicate_id_action end
duplicate_id_warn(id::Symbol)  = @warn( "ID already registered: $id")
duplicate_id_error(id::Symbol) = throw(ArgumentError("ID already registered: $id"))
duplicate_id_none(id::Symbol)  = nothing


"""
$(TYPEDSIGNATURES)

Register `id` symbol and return the symbol.
"""
register_id!(reg::PnmlIDRegistry, s::AbstractString) = register_id!(reg, Symbol(s))
function register_id!(reg::PnmlIDRegistry, id::Symbol)
    lock(reg.lk) do
        id ∈ reg.ids && reg.duplicate(id)
        push!(reg.ids, id)
    end
    id
end

"""
$(TYPEDSIGNATURES)

Return `true` if `s` is registered in `reg`.
"""
isregistered_id(reg::PnmlIDRegistry, s::AbstractString) = isregistered_id(reg, Symbol(s))
function isregistered_id(reg::PnmlIDRegistry, id::Symbol)
    lock(reg.lk) do
        id ∈ reg.ids
    end
end

"""
$(TYPEDSIGNATURES)

Empty the set of id symbols. Use case is unit tests.
In normal use it should never be needed.
"""
function reset_registry!(reg::PnmlIDRegistry)
    lock(reg.lk) do
        empty!(reg.ids)
    end
end

"""
$(TYPEDSIGNATURES)

Is the set of id symbols empty?
"""
function Base.isempty(reg::PnmlIDRegistry)
    lock(reg.lk) do
        isempty(reg.ids)
    end
end

end # module PnmlIDRegistrys
