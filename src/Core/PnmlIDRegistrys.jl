"""
Petri Net Markup Language identifier registry.
"""
module PnmlIDRegistrys
using Preferences
using DocStringExtensions
using Base: @kwdef
#using Base.Threads
export PnmlIDRegistry, register_id!, isregistered, registry

"""
Holds a set of pnml id symbols and a lock to allow safe reentrancy.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct PnmlIDRegistry{L}
    ids::Set{Symbol}
    lk::L
    #!#duplicate::F # Which action for duplicated id.
end

"""
    registry([lock]) -> PnmlIDRegistry

Construct a PNML ID registry using the supplied lock or a `ReentrantLock``.
"""
function registry end
registry() = begin
    _lock_it = @load_preference("lock_registry", false)
    registry(_lock_it ? ReentrantLock() : nothing)
end
registry(lock) = PnmlIDRegistry(Set{Symbol}(), lock)

function Base.show(io::IO, idregistry::PnmlIDRegistry)
    print(io, typeof(idregistry), " ", length(idregistry.ids), " ids: ", idregistry.ids)
    # , " duplicate action: ", nameof(idregistry.duplicate))
end

duplicate_id_warn(id::Symbol)  = @warn(lazy"ID already registered: $id")
duplicate_id_error(id::Symbol) = throw(ArgumentError(lazy"ID already registered: $id"))
duplicate_id_none(_::Symbol)  = nothing

Base.Enums.@enum DuplicateActions none warn error

"""
$(TYPEDSIGNATURES)

Register `id` symbol and return the symbol.
"""
function register_id!(idregistry::PnmlIDRegistry, s::AbstractString)
    register_id!(idregistry, Symbol(s))
end

#function register_id!(idregistry::PnmlIDRegistry, id::Symbol)::Symbol
#    _register_id!(idregistry, id)
#end

function register_id!(idregistry::PnmlIDRegistry{L}, id::Symbol)::Symbol where {L <: Base.AbstractLock}
    @lock idregistry.lk begin
        id ∈ idregistry.ids && duplicate_id_warn(id)
        push!(idregistry.ids, id)
    end
    return id
end

function register_id!(idregistry::PnmlIDRegistry{Nothing}, id::Symbol)::Symbol
    push!(idregistry.ids, id)
    return id
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
function reset!(idregistry::PnmlIDRegistry{L}) where {L <: Base.AbstractLock}
    @lock idregistry.lk empty!(idregistry.ids)
    end
function reset!(idregistry::PnmlIDRegistry{Nothing})
    empty!(idregistry.ids)
end

"""
$(TYPEDSIGNATURES)

Is the set of id symbols empty?
"""
function Base.isempty(idregistry::PnmlIDRegistry{L})::Bool where {L <: Base.AbstractLock}
    @lock idregistry.lk isempty(idregistry.ids)
end
function Base.isempty(idregistry::PnmlIDRegistry{Nothing})::Bool
    isempty(idregistry.ids)
end

end # module PnmlIDRegistrys
