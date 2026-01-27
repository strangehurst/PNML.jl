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

# """
# $(TYPEDSIGNATURES)
# For sorts to be the same, first they must have the same type.
# Then any contents of the sorts are compared semantically.
# """
# equals(a::T, b::T) where {T <: AbstractSort} = equalSorts(a, b) # Are same sort type.
# equals(a::AbstractSort, b::AbstractSort) = false # Not the same sort.

# Returns true if sorts are semantically  #! should be the same sort, even in two different objects.
# Ex: two FiniteEnumerations F1 = {1,4,6} and F2 = {1,4,6} or two Integers I1 and I2.
# Unless they have content, just the types are sufficent.
# Use @auto_hash_equals on all sorts so that these compare item, by, item. Could use hashes.
# Called when both a and b are the same concrete type.
equalSorts(a::AbstractSort, b::AbstractSort, ::AbstractPnmlNet) = a == b

basis(a::AbstractSort) = sortref(a)::AbstractSortRef
sortof(a::AbstractSort, ::AbstractPnmlNet) = identity(a)
sortdefinition(a::AbstractSort) = identity(a)

"""
Built-in sort whose `eltype` is `Bool`

Operators: and, or, not, imply

Functions: equality, inequality
"""
@auto_hash_equals struct BoolSort <: AbstractSort end
Base.eltype(::Type{<:BoolSort}) = Bool
"Elements of boolean sort"
sortelements(::BoolSort, ::AbstractPnmlNet) = tuple(true, false)

#------------------------------------------------------------------------------

"""
$(TYPEDEF)

Wrap a SortRef. Warning: do not cause recursive multiset Sorts.
"""
@auto_hash_equals fields=basis struct MultisetSort{S <: AbstractSortRef} <: AbstractSort
    basis::S

    MultisetSort(b::AbstractSortRef, ddict) = MultisetSort{SortRef.Type}(b, ddict)

    function MultisetSort{S}(b, net::AbstractPnmlNet) where {S <: AbstractSortRef}
        if (isa_variant(b, NamedSortRef) &&
            isa(sortdefinition(namedsort(decldict(net), refid(b))), MultisetSort)) ||
           isa_variant(b, MultisetSortRef)
            throw(PNML.MalformedException("basis cannot be MultisetSort, found $b"))
        end
        new{S}(b)
    end
end

sortref(ms::MultisetSort) = identity(ms.basis)::AbstractSortRef
sortof(ms::MultisetSort, net::AbstractPnmlNet) = sortdefinition(namedsort(decldict(net), basis(ms)::AbstractSortRef)) #TODO abstract
basis(ms::MultisetSort) = ms.basis

function Base.show(io::IO, us::MultisetSort)
    print(io, PNML.indent(io), "MultisetSort(", repr(basis(us)), ")")
end

"""
$(TYPEDEF)

An ordered collection of sorts. The elements of the sort are tuples of elements of each sort.

ISO 15909-1:2019 Concept 14 (color domain) finite cartesian product of color classes.
Where sorts are the syntax for color classes and ProductSort is the color domain.
"""
@auto_hash_equals fields=ae typearg=true cache=true struct ProductSort{N} <: AbstractSort
    ae::NTuple{N, SortRef.Type} #! AbstractSortRef
end

isproductsort(::ProductSort) = true
isproductsort(::Any) = false
Base.length(ps::ProductSort, ddict) = length(sorts(ps, ddict))

"""
    sorts(ps::ProductSort, ddict::DeclDict) -> NTuple
Return iterator over `SortRef`s to sorts in the product.
"""
sorts(ps::ProductSort, ddict::DeclDict) = values(ps.ae)

function sorts(psr::AbstractSortRef, ddict::DeclDict)
    ps = PNML.productsort(ddict, refid(psr))::ProductSort
    sorts(ps, ddict)
end

function sortelements(ref::AbstractSortRef, net::AbstractPnmlNet)
    sortelements(PNML.Parser.to_sort(ref, net), net)
end

# return tuple = product of elements of each sort of ProductSort
function sortelements(ps::ProductSort, net::AbstractPnmlNet) # Iterators.product does tuples
    # sortref to sort to sortelements
    Iterators.product(Fix2(sortelements, net).(sorts(ps, decldict(net)))...)
end

function equalSorts(a::ProductSort{N}, b::ProductSort{N}, net::AbstractPnmlNet) where {N <: Integer}
    if length(a) == length(b) &&
            all(refid(x) == refid(y) for (x,y) in zip(sorts(a, decldict(net)), sorts(b, decldict(net))))
        return true
    end
    return false
end

#
function equalSorts(a::AbstractSortRef, b::AbstractSortRef, net::AbstractPnmlNet)
    if variant_type(a) == variant_type(b) && refid(a) == refid(b)
        #println("Same type ref and same refid means same sortdefinition.")
        return true
    else
        # Compare sortdefinitions.function
        #@show a
        asort = PNML.Parser.to_sort(isa_variant(a, NamedSortRef) ? sortdefinition(namedsorts(decldict(net))[refid(a)]) : a, net)
        #@show b
        bsort = PNML.Parser.to_sort(isa_variant(b, NamedSortRef) ? sortdefinition(namedsorts(decldict(net))[refid(b)]) : b, net)
        return equalSorts(asort, bsort, net)
    end
end

# equalSorts(a::NamedSortRef, b::UserSortRef, net) = equalSorts(a, convert(NamedSortRef, b), net)
# equalSorts(a::UserSortRef, b::NamedSortRef, net) = equalSorts(convert(NamedSortRef, a), b, net)
# equalSorts(a::UserSortRef, b::UserSortRef, net) = equalSorts(convert(NamedSortRef, a), convert(NamedSortRef, b), net)


function Base.show(io::IO, ps::ProductSort)
    print(io, PNML.indent(io), "ProductSort(", ps.ae, ")")
end
