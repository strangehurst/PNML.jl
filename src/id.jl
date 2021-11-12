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
#const GlobalIDRegistry = IDRegistry()


const DUPLICATE_ID_ACTION=nothing

"""
$(TYPEDSIGNATURES)

Use a global configuration to choose what to do when a duplicated pnml node id
has been detected. Default is to do nothing.
"""
function duplicate_id_action(id::Symbol)
    DUPLICATE_ID_ACTION === :warn && @warn "ID '$(id)' already registered"
    DUPLICATE_ID_ACTION === :error && error("ID '$(id)' already registered in  $(reg.ids)")
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
#Count and lock to implement global state."
"""
$(TYPEDEF)

$(TYPEDFIELDS)
"""
mutable struct MissingIDCounter
    i::Int
    lk::ReentrantLock
end
MissingIDCounter() = MissingIDCounter(0, ReentrantLock())

#Increment counter and return new value."
"""
$(TYPEDSIGNATURES)
"""
function next_missing_id(c::MissingIDCounter)
    lock(c.lk) do
        c.i += 1
    end 
end
