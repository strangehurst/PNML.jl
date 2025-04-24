Base.eltype(::Type{<:AbstractSort}) = Int

"""
Tuple of sort IDs that are considered builtin.
There will be a version defined for each in the `DECLDICT[]`.
Users may (re)define these.
"""
builtin_sorts() = (:integer, :natural, :positive, :real, :dot, :bool, :null,)
#todo Use set instead of tuple?

"""
    isbuiltinsort(::Symbol) -> Bool

Is tag in `builtin_sorts()`.
"""
isbuiltinsort(tag::Symbol) = (tag in builtin_sorts())

"""
$(TYPEDSIGNATURES)
For sorts to be the same, first they must have the same type.
Then any contents of the sorts are compared semantically.
"""
equals(a::T, b::T) where {T <: AbstractSort} = equalSorts(a, b) # Are same sort type.
equals(a::AbstractSort, b::AbstractSort) = false # Not the same sort.

# Returns true if sorts are semantically  #! should be usersortthe same sort, even in two different objects.
# Ex: two FiniteEnumerations F1 = {1,4,6} and F2 = {1,4,6} or two Integers I1 and I2.
# Unless they have content, just the types are sufficent.
# Use @auto_hash_equals on all sorts so that these compare item, by, item. Could use hashes.
# Called when both a and b are the same concrete type.
equalSorts(a::AbstractSort, b::AbstractSort) = a == b

basis(a::AbstractSort) = sortref(a)::UserSort
sortof(a::AbstractSort) = identity(a)
#! sortelements(::AbstractSort) = () # sort that has no elements will lead to errors!

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

Holds a reference id (REFID) to a subtype of SortDeclaration.

[`PNML.Declarations.NamedSort`](@ref) is used to construct a sort out of builtin sorts.
"""
@auto_hash_equals fields=declaration struct UserSort <: AbstractSort
    declaration::REFID #TODO validate as a NamedSort REFID
end
refid(us::UserSort) = us.declaration

"Get NamedSort from UserSort REFID"
namedsort(us::UserSort) = namedsort(refid(us)) # usersort -> namedsort
sortref(us::UserSort) = identity(us)::UserSort
sortof(us::UserSort) = sortdefinition(namedsort(us))
Base.eltype(us::UserSort) = eltype(sortof(us))

# Forward operations to the NamedSort matching the declaration REFID.
sortelements(us::UserSort) = sortelements(sortdefinition(namedsort(us)))
name(us::UserSort) = name(namedsort(us))

isproductsort(us::UserSort) = sortdefinition(namedsort(us)) isa ProductSort

"""
$(TYPEDEF)

Wrap a UserSort. Warning: do not cause recursive multiset Sorts.
"""
@auto_hash_equals struct MultisetSort <: AbstractSort
    basis::UserSort
    function MultisetSort(b::UserSort)
        if isa(sortdefinition(namedsort(b)), MultisetSort)
            throw(PNML.MalformedException("MultisetSort basis cannot be MultisetSort"))
        else
            new(b)
        end
    end
end
sortref(ms::MultisetSort) = identity(ms.basis)::UserSort # 2024-10-09 make be a usersort
sortof(ms::MultisetSort) = sortdefinition(namedsort(basis(ms)::UserSort)) #TODO abstract
basis(ms::MultisetSort) = ms.basis

"""
$(TYPEDEF)

An ordered collection of sorts. The elements of the sort are tuples of elements of each sort.

ISO 15909-1:2019 Concept 14 (color domain) finite cartesian product of color classes.
Where sorts are the syntax for color classes and ProduceSort is the color domain.
"""
@auto_hash_equals struct ProductSort{N} <: AbstractSort
    ae::NTuple{N,REFID}
end
isproductsort(::ProductSort) = true
isproductsort(::Any) = false

"""
    sorts(ps::ProductSort) -> NTuple
Return sorts that are in the product.
"""
sorts(ps::ProductSort) = ps.ae

sortelements(ps::ProductSort) = Iterators.product((sortelements ∘ usersort).(sorts(ps))...)

sortof(ps::ProductSort) = begin
    println("sortof(::ProductSort ", s) #! bringup debug
    if isempty(sorts(ps))
        error("ProductSort is empty")
    else
        (map(sortof, sorts(ps)...),) # map REFIDs to tuple of sorts
    end
end
