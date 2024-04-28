
Base.eltype(::Type{<:AbstractSort}) = Int

"Return network id of sort."
netid(s::AbstractSort) = hasproperty(s, ids) ? first(getproperty(s, ids)) : error("$(typeof(s)) missing id tuple")
sortof(s::AbstractSort) = hasproperty(s, sort) ? first(getproperty(s, sort)) : error("$(typeof(s)) missing sort declaration")

"""
$(TYPEDSIGNATURES)
For sorts to be the same, first the must have the same type.
Then any contents of the sorts are compared semantically.
"""
equals(a::T, b::T) where {T <: AbstractSort} = equalSorts(a, b)
equals(a::AbstractSort, b::AbstractSort) = false # Not the same sort.

# Returns true if sorts are semantically the same sort, even in two different objects.
# Ex: two FiniteEnumerations F1 = {1,4,6} and F2 = {1,4,6} or two Integers I1 and I2.
# Unless they have content just the types are sufficent.
# Use @auto_hash_equals on all sorts so that these compare item, by, item. Could use hashes.
# Called when both a and b are the same concrete type.
equalSorts(a::AbstractSort, b::AbstractSort) = a == b

"""
Built-in sort whose `eltype` is `Bool`

Operators: and, or, not, imply

Functions: equality, inequality
"""
@auto_hash_equals struct BoolSort <: AbstractSort end
Base.eltype(::Type{<:BoolSort}) = Bool


#------------------------------------------------------------------------------
"""
$(TYPEDEF)

Holds a reference id to a concrete subtype of [`SortDeclaration`](@ref).

[`NamedSort`](@ref) is used to construct a sort out of builtin types.
Used in a `Place`s sort type property.
"""
@auto_hash_equals struct UserSort <: AbstractSort
    declaration::Symbol #TODO validate as a NamedSort
    ids::Tuple
end
UserSort(s::Symbol; ids::Tuple) = UserSort(s, ids)
UserSort() = UserSort(:nothing, (:NN,))
# Return sort of the referenced named sort.
sortof(us::UserSort) = sortof(named_sort(decldict(first(us.ids)), us.declaration))

"""
$(TYPEDEF)

Wrap a Sort. Warning: do not cause recursive multiset Sorts.
"""
@auto_hash_equals struct MultisetSort{T <: AbstractSort} <: AbstractSort
    multi::Int
    us::T
    MultisetSort(n,s) = if isa(s, MultisetSort)
        throw(MalformedException("MultisetSort basis cannot be MultisetSort"))
    else
        new{typeof(s)}(n,s)
    end
end
MultisetSort() = MultisetSort(1,IntegerSort())

"""
$(TYPEDEF)

An ordered collection of sorts.
"""
@auto_hash_equals struct ProductSort <: AbstractSort
    ae::Vector{AbstractSort} #! any sort types? UserSort and BuiltinSorts
end
ProductSort() = ProductSort(UserSort[])


"""
$(TYPEDSIGNATURES)
Return instance of default sort based on `PNTD`.
"""
function default_sort end
default_sort(x::Any) = throw(ArgumentError(string("no default sort for ", typeof(x))))
default_sort(pntd::PnmlType) = default_sort(typeof(pntd))
default_sort(::Type{<:PnmlType}) = IntegerSort
default_sort(::Type{<:AbstractContinuousNet}) = RealSort
