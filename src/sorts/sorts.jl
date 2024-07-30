Base.eltype(::Type{<:AbstractSort}) = Int

"""
$(TYPEDSIGNATURES)
For sorts to be the same, first they must have the same type.
Then any contents of the sorts are compared semantically.
"""
equals(a::T, b::T) where {T <: AbstractSort} = equalSorts(a, b) # Are same sort type.
equals(a::AbstractSort, b::AbstractSort) = false # Not the same sort.

# Returns true if sorts are semantically the same sort, even in two different objects.
# Ex: two FiniteEnumerations F1 = {1,4,6} and F2 = {1,4,6} or two Integers I1 and I2.
# Unless they have content just the types are sufficent.
# Use @auto_hash_equals on all sorts so that these compare item, by, item. Could use hashes.
# Called when both a and b are the same concrete type.
equalSorts(a::AbstractSort, b::AbstractSort) = a == b

basis(a::AbstractSort) = sortof(a)
sortof(a::AbstractSort) = identity(a)
sortelements(::AbstractSort) = ()

"""
Built-in sort whose `eltype` is `Bool`

Operators: and, or, not, imply

Functions: equality, inequality
"""
@auto_hash_equals struct BoolSort <: AbstractSort end
Base.eltype(::Type{<:BoolSort}) = Bool
"Elements of boolean sort"
sortelements(::BoolSort) = tuple(true, false)

#------------------------------------------------------------------------------
"""
$(TYPEDEF)

Holds a reference id (REFID) to a subtype of Declaratons.SortDeclaration.

[`PNML.Declarations.NamedSort`](@ref) is used to construct a sort out of builtin sorts.
Used in a Place's sort type property.
"""
@auto_hash_equals fields=declaration struct UserSort <: AbstractSort
    declaration::Symbol #TODO validate as a NamedSort
end

"Access the referenced named sort declaration."
_access_decl(us::UserSort) = named_sort(DECLDICT[], us.declaration)

# Forward operations to the UserSort having a pid matching the declaration REFID.
sortof(us::UserSort) = sortof(_access_decl(us))
sortelements(us::UserSort) = sortelements(_access_decl(us))
pid(us::UserSort) = pid(_access_decl(us)) # Do we have to do this here? (it could be an assertion)
name(us::UserSort) = name(_access_decl(us)) # This we DO have to do here.

"""
$(TYPEDEF)

Wrap a Sort. Warning: do not cause recursive multiset Sorts.
"""
@auto_hash_equals struct MultisetSort{T <: AbstractSort} <: AbstractSort
    basis::T
    MultisetSort(s) = if isa(s, MultisetSort)
        throw(MalformedException("MultisetSort basis cannot be MultisetSort"))
    else
        new{typeof(s)}(s)
    end
end
sortof(ms::MultisetSort) = ms.basis
basis(ms::MultisetSort) = ms.basis

multisetsort(basis::AbstractSort) = MultisetSort(basis)

"""
$(TYPEDEF)

An ordered collection of sorts.
"""
@auto_hash_equals struct ProductSort <: AbstractSort
    ae::Vector{AbstractSort} #! any sort types? UserSort and BuiltinSorts
end
ProductSort() = ProductSort(UserSort[])
# sortof(ps::ProductSort) is a vector/tuple of sorts

#------------------------------------------------------------------------------
"""
    TupleSort holds tuple of sorts. One for each of the elements of the <tuple>.

PnmlTuples have a similarity to NamedTuples with Sorts taking the place of names.
Will not achieve the same transparancy and efficency as NamedTuples.

"""
@auto_hash_equals struct TupleSort <: AbstractSort
    tup::Vector{AbstractSort} #! any sort types? UserSort and BuiltinSorts
end
TupleSort() = TupleSort(UserSort[])

function sortof(ts::TupleSort)
    println("sortof(::TupleSort: ", ts) #! bringup debug
    if isempty(ts.tup)
        @error "TupleSort is empty, require as many sorts as the tuple has elements, return NullSort"
        NullSort()
    else
        sortof(first(ts.tup)) #TODO set of sorts, iterator
    end
end
