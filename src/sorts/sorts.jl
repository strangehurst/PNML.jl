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
    declaration::REFID #TODO validate as a NamedSort REFID
end
refid(us::UserSort) = us.declaration

"Get NamedSort from UserSort REFID"
namedsort(us::UserSort) = namedsort(refid(us)) # usersort -> namedsort
sortref(us::UserSort) = us
sortof(us::UserSort) = sortdefinition(namedsort(us))

# Forward operations to the NamedSort matching the declaration REFID.
sortelements(us::UserSort) = sortelements(sortdefinition(namedsort(us)))
name(us::UserSort) = name(namedsort(us))

"""
$(TYPEDEF)

Wrap a UserSort. Warning: do not cause recursive multiset Sorts.
"""
@auto_hash_equals struct MultisetSort <: AbstractSort
    basis::UserSort
    function MultisetSort(b::UserSort)
        if isa(sortdefinition(namedsort(b)), MultisetSort)
            throw(MalformedException("MultisetSort basis cannot be MultisetSort"))
        else
            new(b)
        end
    end
end
sortref(ms::MultisetSort) = ms.basis # 2024-10-09 make be a usersort
sortof(ms::MultisetSort) = sortdefinition(namedsort(basis(ms))) #TODO abstract
basis(ms::MultisetSort) = ms.basis

"""
$(TYPEDEF)

An ordered collection of sorts.
"""
@auto_hash_equals struct ProductSort <: AbstractSort
    ae::Vector{REFID} #! NamedSorts and UserSorts are linked by REFIDs
end
ProductSort() = ProductSort(REFID[])
# sortof(ps::ProductSort) is a vector/tuple of sorts

#------------------------------------------------------------------------------
"""
    TupleSort holds tuple of sorts. One for each of the elements of the <tuple>.

PnmlTuples have a similarity to NamedTuples with Sorts taking the place of names.
Will not achieve the same transparancy and efficency as NamedTuples.

"""
@auto_hash_equals struct TupleSort <: AbstractSort
    tup::Vector{REFID} #! UserSort REFIDs
end
TupleSort() = TupleSort(REFID[])

function sortof(ts::TupleSort)
    println("sortof(::TupleSort: ", ts) #! bringup debug
    if isempty(ts.tup)
        @error "TupleSort is empty, require as many sorts as the tuple has elements, return NullSort"
        NullSort()
    else
        sortof(first(ts.tup)) #TODO set of sorts, iterator
    end
end
