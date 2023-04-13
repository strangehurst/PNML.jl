"""
Petri Net Markup Language identifier registry.
"""
module PnmlIDRegistrys

using DocStringExtensions
using Base: @kwdef
#using Base.Threads
export PnmlIDRegistry, register_id!, isregistered_id, registry

"""
Holds a set of pnml id symbols and a lock to allow safe reentrancy.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct PnmlIDRegistry{L <: Base.AbstractLock}
    ids::Set{Symbol}
    lk::L
    #!#duplicate::F
end
"""
    registry([lock]) -> PnmlIDRegistry

Construct a PNML ID registry using the supplied lock or a `ReentrantLock``.
"""
function registry end
registry() = registry(ReentrantLock())
registry(lock::L) where {L <: Base.AbstractLock} = PnmlIDRegistry(Set{Symbol}(), lock)

function Base.show(io::IO, idregistry::PnmlIDRegistry)
    print(io, typeof(idregistry), " ", length(idregistry.ids), " ids: ", idregistry.ids)
    # , " duplicate action: ", nameof(idregistry.duplicate))
end

duplicate_id_warn(id::Symbol)  = @warn( "ID already registered: $id")
duplicate_id_error(id::Symbol) = throw(ArgumentError("ID already registered: $id"))
duplicate_id_none(_::Symbol)  = nothing

Base.Enums.@enum DuplicateActions none warn error

"""
$(TYPEDSIGNATURES)

Register `id` symbol and return the symbol.
"""
function register_id!(idregistry::PnmlIDRegistry, s::AbstractString)
    register_id!(idregistry, Symbol(s))
end
function register_id!(idregistry::PnmlIDRegistry, id::Symbol)::Symbol
    @nospecialize
    @lock idregistry.lk begin
        id ∈ idregistry.ids && duplicate_id_warn(id)
        push!(idregistry.ids, id)
    end
    return id
end

"""
$(TYPEDSIGNATURES)

Return `true` if `s` is registered in `reg`.
"""
isregistered_id(reg::PnmlIDRegistry, s::AbstractString) = isregistered_id(reg, Symbol(s))
function isregistered_id(idregistry::PnmlIDRegistry, id::Symbol)::Bool
    @nospecialize
    lock(idregistry.lk) do
        id ∈ idregistry.ids
    end
end

"""
$(TYPEDSIGNATURES)

Empty the set of id symbols. Use case is unit tests.
In normal use it should never be needed.
"""
function reset!(idregistry::PnmlIDRegistry)
    @nospecialize
    lock(idregistry.lk) do
        empty!(idregistry.ids)
    end
end

"""
$(TYPEDSIGNATURES)

Is the set of id symbols empty?
"""
function Base.isempty(idregistry::PnmlIDRegistry)::Bool
    @nospecialize
    lock(idregistry.lk) do
        isempty(idregistry.ids)
    end
end

end # module PnmlIDRegistrys
