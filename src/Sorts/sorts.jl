"""
Tuple of sort IDs that are considered builtin.
There will be a version defined for each in the `DeclDict`.
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

# Returns true if sorts are semantically  #! should be the same sort, even in two different objects.
# Ex: two FiniteEnumerations F1 = {1,4,6} and F2 = {1,4,6} or two Integers I1 and I2.
# Unless they have content, just the types are sufficent.
# Use @auto_hash_equals on all sorts so that these compare item, by, item. Could use hashes.
# Called when both a and b are the same concrete type.
equalSorts(a::AbstractSort, b::AbstractSort) = a == b

basis(a::AbstractSort) = sortref(a)::SortRef
sortof(a::AbstractSort) = identity(a)

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

Holds a reference id (REFID) to a subtype of `SortDeclaration` stored in a `DeclDict`.

[`PNML.Declarations.NamedSort`](@ref) is used to construct a sort out of builtin sorts.
Also [`PNML.Declarations.ArbitrarySort`](@ref), [`PNML.Declarations.PartitionSort`](@ref).
"""
@auto_hash_equals fields=declaration struct UserSort <: AbstractSort
    declaration::REFID #TODO validate REFID in `DeclDict`
    declarationdicts::DeclDict
end

# `<productsort>` defines a tuple of sorts.
# Related to PNML `<tuple>` operator) that returns a Julia `tuple` of elements of sorts.
# `<variabledecl` links a sort with a name & REFID. `<variable` accesses by REFID.

#? todo is the name the unique identifier of a variable?

# ePNK uses `<namedoperator>` `<parameter>` `<variabledecl` to map the ordered arguments
# to the expression variables in `<def>`
# and for `<place><type>` label `<structure>`.

#! Can also be ProductSort, MultisetSort. ePNK uses inline sorts.

#! Sorts can be inline in a variabledecl as part of useroperator, sorttype (anywhere else?)
#! They will be concrete types.
#! no dynamic behavior re embedded sorts during enabling/firing rules. (treat as constant)
#! cache any values that need calculating
#! want to use REFIDs to avoid the need to define Types.

#^ productsort is a tuple of 0 or more sorts
#^ may nest productsort in a productsort (not true for multisetsort)
#^ see also multisetsort that has a basis sort (that can be a productsort)

#~ We create user/named duos for each built-in sort.

refid(us::UserSort) = us.declaration
decldict(us::UserSort) = us.declarationdicts

"Get NamedSort from UserSort REFID"
namedsort(us::UserSort) = namedsort(decldict(us), refid(us))::PNML.Declarations.NamedSort #todo partitionsort, arbitrarysort
sortref(us::UserSort) = identity(us)::SortRef
sortof(us::UserSort) = sortdefinition(namedsort(us)) #^ ArbitrarySort, PartitionSort, ProductSort
Base.eltype(us::UserSort) = eltype(sortof(us))

# Forward operations to the NamedSort matching the declaration REFID.
function sortelements(us::UserSort)
    ns = namedsort(us) #todo can be partitionsort, arbitrarysort sort declaration.
    sortelements(ns)
end


name(us::UserSort) = name(namedsort(us))

function Base.show(io::IO, us::UserSort)
    print(io, PNML.indent(io), "UserSort(", repr(refid(us)), ")")
end

isproductsort(us::UserSort) = isa(sortdefinition(namedsort(us)), ProductSort)

"""
$(TYPEDEF)

Wrap a UserSort. Warning: do not cause recursive multiset Sorts.
"""
@auto_hash_equals fields=basis struct MultisetSort <: AbstractSort
    basis::SortRef
    declarationdicts::PNML.DeclDict

    function MultisetSort(b::SortRef, ddict)
        if isa(sortdefinition(namedsort(ddict, refid(b))), MultisetSort)
            throw(PNML.MalformedException("MultisetSort basis cannot be MultisetSort"))
        else
            new(b, ddict)
        end
    end
end

decldict(ms::MultisetSort) = ms.declarationdicts
sortref(ms::MultisetSort) = identity(ms.basis)::SortRef # 2025-06-28 make be a SortRef
sortof(ms::MultisetSort) = sortdefinition(namedsort(decldict(ms), basis(ms)::SortRef)) #TODO abstract
basis(ms::MultisetSort) = ms.basis

function Base.show(io::IO, us::MultisetSort)
    print(io, PNML.indent(io), "MultisetSort(", repr(basis(us)), ")")
end

"""
$(TYPEDEF)

An ordered collection of sorts. The elements of the sort are tuples of elements of each sort.

ISO 15909-1:2019 Concept 14 (color domain) finite cartesian product of color classes.
Where sorts are the syntax for color classes and ProduceSort is the color domain.
"""
@auto_hash_equals fields=ae typearg=true cache=true struct ProductSort{N} <: AbstractSort
    ae::NTuple{N,REFID} #! todo SortRef
    declarationdicts::DeclDict
end

decldict(ps::ProductSort) = ps.declarationdicts
isproductsort(::ProductSort) = true
isproductsort(::Any) = false

"""
    sorts(ps::ProductSort) -> NTuple
Return iterator over tuples of elements of sorts in the product.
"""
sorts(ps::ProductSort) = ps.ae

function sortelements(ps::ProductSort) # Iterators.product does tuples
    #!@show sorts(ps)
    # for s in sorts(ps)
    #     @show sortelements(namedsort(decldict(ps), s))
    # end
    Iterators.product((sortelements ∘ Fix1(namedsort, decldict(ps))).(sorts(ps))...)
end

function sortof(ps::ProductSort)
    println("sortof(::ProductSort ", ps) #! bringup debug
    if isempty(sorts(ps))
        error("ProductSort is empty")
    else
        (map(sortof, sorts(ps)...),) # map REFIDs to tuple of sorts
    end
end

function Base.show(io::IO, ps::ProductSort)
    print(io, PNML.indent(io), "ProductSort(", ps.ae, ")")
end

#------------------------------------------------------------------
"""
Union of UserSort, ProductSort{N},  MultisetSort.
"""
const Sort{N} = Union{UserSort, ProductSort{N},  MultisetSort}
#TODO PNML.Declarations.ArbitrarySort
