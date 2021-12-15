# PNML id registry and related function.
"""
$(TYPEDEF)

$(TYPEDFIELDS)

Holds a set of pnml id symbols and a lock to allow safe reentrancy.
"""
mutable struct IDRegistry
    ids::Set{Symbol}
    lk::ReentrantLock
end

IDRegistry() = IDRegistry(Set{Symbol}(), ReentrantLock())

function Base.show(io::IO, reg::IDRegistry)
    print(io, "PNML.IDRegistry ", length(reg.ids), " ids: ", reg.ids)
end


const DUPLICATE_ID_ACTION=nothing

"""
$(TYPEDSIGNATURES)

Choose what to do when a duplicated pnml node id has been detected.
Default `action` is to do nothing.
"""
function duplicate_id_action(id::Symbol; action=nothing)
    action === :warn && @warn "ID '$(id)' already registered"
    action === :error && error("ID '$(id)' already registered in  $(reg.ids)")
    return nothing
end

#TODO rename register_id! to push!
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

"""
$(TYPEDSIGNATURES)
"""
function Base.isempty(reg::IDRegistry)
    lock(reg.lk) do
        isempty(reg.ids)
    end
end

#-------------------------------------------------------------------
#TODO: Make global state varaible.
"""
$(TYPEDEF)

$(TYPEDFIELDS)
Count and lock to implement global state.
"""
mutable struct MissingIDCounter
    i::Int
    lk::ReentrantLock
end
MissingIDCounter() = MissingIDCounter(0, ReentrantLock())

"""
$(TYPEDSIGNATURES)

Increment counter and return new value.
"""
function next_missing_id(c::MissingIDCounter)
    lock(c.lk) do
        c.i += 1
    end 
end
