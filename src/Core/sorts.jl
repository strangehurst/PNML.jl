"""
$(TYPEDEF)
Part of the high-level pnml many-sorted algebra. See  [`SortType`](@ref).

NamedSort is an AbstractTerm that declares a definition using an AbstractSort.
The pnml specification sometimes uses overlapping language.

From the 'primer': built-in sorts of Symmetric Nets are the following:
booleans, integerrange, finite enumerations, cyclic enumerations, permutations and dots.

The `eltype` is expected to be a concrete subtype of `Number` such as `Int`, `Bool` or `Float64`.

# Extras

Notes:
- `NamedSort` is a [`SortDeclaration`](@ref). [`HLPNG`](@ref) adds [`ArbitrarySort`](@ref).
- `UserSort` holds the id symbol of a `NamedSort`.
- Here 'type' means a 'term' from the many-sorted algebra.
- We use sorts even for non-high-level nets.
- Expect `eltype(::AbstractSort)` to return a concrete subtype of `Number`.
"""
abstract type AbstractSort end
Base.eltype(::Type{<:AbstractSort}) = Int

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

"""
Built-in sort whose `eltype` is `Int`
"""
@auto_hash_equals struct DotSort <: AbstractSort end
Base.eltype(::Type{<:DotSort}) = Int

"""
Built-in sort whose `eltype` is `Int`
"""
@auto_hash_equals struct IntegerSort <: AbstractSort end
Base.eltype(::Type{<:IntegerSort}) = Int

"""
Built-in sort whose `eltype` is `Int`
"""
@auto_hash_equals struct NaturalSort <: AbstractSort end
Base.eltype(::Type{<:NaturalSort}) = Int # Uint ?

"""
Built-in sort whose `eltype` is `Int`
"""
@auto_hash_equals struct PositiveSort <: AbstractSort end
Base.eltype(::Type{<:PositiveSort}) = Int # Uint ?

"""
Built-in sort whose `eltype` is `Float64`
"""
@auto_hash_equals struct RealSort <: AbstractSort end
Base.eltype(::Type{<:RealSort}) = Float64

#------------------------------------------------------------------------------
"""
$(TYPEDEF)

Holds a reference id to a concrete subtype of [`SortDeclaration`](@ref).

[`NamedSort`](@ref) is used to construct a sort out of builtin types.
Used in a `Place`s sort type property.
"""
@auto_hash_equals struct UserSort <: AbstractSort
    declaration::Symbol #TODO validate as a NamedSort
end
UserSort() = UserSort(:integersort) # Is a built-in sort.
UserSort(s::AbstractString) = UserSort(Symbol(s))
#! equalSorts(a::UserSort, b::UserSort) = a.declaration == b.declaration

"""
$(TYPEDEF)

Wrap a [`UserSort`](@ref). Warning: do not cause recursive multiset Sorts.
"""
@auto_hash_equals struct MultisetSort{T <: AbstractSort} <: AbstractSort
    us::T # But not another MultistSort
end
MultisetSort() = MultisetSort(UserSort())
#! equalSorts(a::MultisetSort, b::MultisetSort) = equalSorts(a.us, b.us)

"""
$(TYPEDEF)

An ordered collection of sorts.
"""
@auto_hash_equals struct ProductSort <: AbstractSort
    ae::Vector{AbstractSort} #! any sort types? UserSort and BuiltinSorts
end
ProductSort() = ProductSort(UserSort[])
#! equalSorts(a::ProductSort, b::ProductSort) = a.ae == b.ae

"""
$(TYPEDEF)
"""
abstract type EnumerationSort <: AbstractSort end

function Base.getproperty(s::EnumerationSort, prop_name::Symbol)
    prop_name === :elements && return getfield(s, :elements)::Vector{FEConstant}
    return getfield(o, prop_name)
end

elements(s::EnumerationSort) = s.elements
#! equalSorts(a::T, b::T) where {T <: EnumerationSort} = elements(a) == elements(b)

"""
$(TYPEDEF)

The operations differ between the various `EnumerationSort`s. They may be #TODO
"""
@auto_hash_equals struct CyclicEnumerationSort <: EnumerationSort
    elements::Vector{FEConstant}
end
CyclicEnumerationSort() = CyclicEnumerationSort(FEConstant[])

"""
$(TYPEDEF)
"""
@auto_hash_equals struct FiniteEnumerationSort <: EnumerationSort
    elements::Vector{FEConstant}
end
FiniteEnumerationSort() = FiniteEnumerationSort(FEConstant[])

function Base.show(io::IO, es::EnumerationSort)
    print(io, nameof(typeof(es)), "([")
    io = inc_indent(io)
    for  (i, c) in enumerate(elements(es))
        print(io, '\n', indent(io)); show(io, values(c));
        i < length(elements(es)) && print(io, ",")
    end
    print(io, "])")
end

"""
$(TYPEDEF)
"""
@auto_hash_equals struct FiniteIntRangeSort{T} <: AbstractSort
    start::T
    stop::T # XML Schema calls this 'end'.
end
FiniteIntRangeSort() = FiniteIntRangeSort(0, 0)
#! equalSorts(a::FiniteIntRangeSort, b::FiniteIntRangeSort) = (a.start == b.start && a.stop == b.stop)
Base.eltype(::FiniteIntRangeSort{T}) where {T} = T

function Base.show(io::IO, s::FiniteIntRangeSort)
    print(io, "FiniteIntRangeSort(", s.start, ", ", s.stop, ")")
end

"""
$(TYPEDEF)
"""
@auto_hash_equals struct StringSort <: AbstractSort
    #
    ae::Vector{AbstractSort}
end
StringSort() = StringSort(IntegerSort[])
#! equalSorts(a::StringSort, b::StringSort) = a.ae == b.ae

function Base.show(io::IO, s::StringSort)
    print(io, "StringSort([")
    io = inc_indent(io)
    for  (i, c) in enumerate(s.ae)
        print(io, '\n', indent(io)); show(io, c);
        i < length(s.ae) && print(io, ",")
    end
    print(io, "])")
end

"""
$(TYPEDEF)
"""
@auto_hash_equals struct ListSort <: AbstractSort
    #
    ae::Vector{AbstractSort}
end
ListSort() = ListSort(IntegerSort[])
#! equalSorts(a::ListSort, b::ListSort) = a.ae == b.ae

function Base.show(io::IO, s::ListSort)
    print(io, "ListSort([")
    io = inc_indent(io)
    for  (i, c) in enumerate(s.ae)
        print(io, '\n', indent(io)); show(io, c);
        i < length(s.ae) && print(io, ",")
    end
    print(io, "])")
end

"""
$(TYPEDSIGNATURES)
Return instance of default sort based on `PNTD`.
"""
function default_sort end
default_sort(x::Any) = (throw ∘ ArgumentError)("no default sort for $(typeof(x))")
default_sort(pntd::PnmlType) = default_sort(typeof(pntd))
default_sort(::Type{<:PnmlType}) = IntegerSort
default_sort(::Type{<:AbstractContinuousNet}) = RealSort
