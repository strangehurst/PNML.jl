# PNML id, id registry and related function.

"""
Holds a set of pnml id symbols and a lock to allow safe reentrancy.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct IDRegistry
    ids::Set{Symbol}
    lk::ReentrantLock
end

IDRegistry() = IDRegistry(Set{Symbol}(), ReentrantLock())

function Base.show(io::IO, reg::IDRegistry)
    print(io, typeof(reg), " ", length(reg.ids), " ids: ", reg.ids)
end

"""
$(TYPEDSIGNATURES)

Duplicated pnml node id has been detected.
Default `action` is to issue a warning.
"""
function duplicate_id_action(id::Symbol; action=:warn)
    action === :warn && @warn "ID '$id' already registered"
    action === :error && error("ID '$id' already registered")
    return nothing
end

"""
$(TYPEDSIGNATURES)

Register `id` symbol and return the symbol.
"""
register_id!(reg::IDRegistry, s::AbstractString) = register_id!(reg, Symbol(s))
function register_id!(reg::IDRegistry, id::Symbol)
    lock(reg.lk) do
        id ∈ reg.ids && duplicate_id_action(id)
        push!(reg.ids, id)
    end
    id
end

"""
$(TYPEDSIGNATURES)

Return `true` if `s` is registered in `reg`.
"""
isregistered(reg::IDRegistry, s::AbstractString) = isregistered(reg, Symbol(s))
function isregistered(reg::IDRegistry, id::Symbol)
    lock(reg.lk) do
        id ∈ reg.ids
    end
end

"""
$(TYPEDSIGNATURES)

Empty the set of id symbols. Use case is unit tests.
In normal use it should never be needed.
"""
function reset_registry!(reg::IDRegistry)
    lock(reg.lk) do
        empty!(reg.ids)
    end
end

function Base.isempty(reg::IDRegistry)
    lock(reg.lk) do
        isempty(reg.ids)
    end
end
