"""
$(TYPEDEF)
Part of the high-level pnml many-sorted algebra. See  [`SortType`](@ref).

NamedSort is an AbstractTerm that declares a definition using an AbstractSort.
The pnml specification sometimes uses overlapping language.

From the 'primer': built-in sorts of Symmetric Nets are the following:
booleans, integerrange, finite enumerations, cyclic enumerations, permutations and dots.

The `eltype` is expected to be a concrete subtype of `Number` such as `Int`, `Bool` or `Float64`.
"""
abstract type AbstractSort end
Base.eltype(::Type{<:AbstractSort}) = Int

#_evaluate(x::AbstractSort) = x() #! functor not for sort?

"Built-in sort whose `eltype` is `Bool`"
struct BoolSort <: AbstractSort end
Base.eltype(::Type{<:BoolSort}) = Bool

"Built-in sort whose `eltype` is `Int`"
struct DotSort <: AbstractSort end
Base.eltype(::Type{<:DotSort}) = Int

"""
"Built-in sort whose `eltype` is `Int`"
"""
struct IntegerSort <: AbstractSort end
Base.eltype(::Type{<:IntegerSort}) = Int

"""
"Built-in sort whose `eltype` is `Int`"
"""
struct NaturalSort <: AbstractSort end
Base.eltype(::Type{<:NaturalSort}) = Int # Uint ?

"""
"Built-in sort whose `eltype` is `Int`"
"""
struct PositiveSort <: AbstractSort end
Base.eltype(::Type{<:PositiveSort}) = Int # Uint ?


"""
"Built-in sort whose `eltype` is `Float64`"
Real numbers are not part of the PNML Specification.
We stick them into the type hierarchy for convenience rather than mathematical correctness.
"""
struct RealSort <: AbstractSort end
Base.eltype(::Type{<:RealSort}) = Float64

"""
$(TYPEDSIGNATURES)
Are the sorts `eltype` the same? First the must have the same type. Then any contents of the sorts are compared.
"""
equals(a::T, b::T) where {T <: AbstractSort} = equalSorts(a, b)
equals(a::AbstractSort, b::AbstractSort) = false

# Unless they have content, for example an enumeration, just the types are sufficent.
equalSorts(a::AbstractSort, b::AbstractSort) = true
#= From pnmlframework
Returns true if sorts are semantically the same sort, even in two different objects.
Ex: two FiniteEnumerations F1 = {1,4,6} and F2 = {1,4,6} or two Integers I1 and I2.
=#

#------------------------------------------------------------------------------
"""
$(TYPEDEF)

Holds a reference id to a concrete subtype of [`SortDeclaration`](@ref).

[`NamedSort`](@ref) is used to construct a sort out of builtin types.
Used in a `Place`s sort type property.
"""
struct UserSort <: AbstractSort
    declaration::Symbol
end
UserSort() = UserSort(:integer)
UserSort(s::AbstractString) = UserSort(Symbol(s))
equalSorts(a::UserSort, b::UserSort) = a.declaration == b.declaration

"""
$(TYPEDEF)

Wrap a [`UserSort`](@ref). Warning: do not cause recursive multiset Sorts.
"""
struct MultisetSort <: AbstractSort
    us::UserSort
end
MultisetSort() = MultisetSort(UserSort())
equalSorts(a::MultisetSort, b::MultisetSort) = a.us == b.us

"""
$(TYPEDEF)

An ordered collection of sorts.
"""
struct ProductSort <: AbstractSort
    ae::Vector{UserSort}
end
ProductSort() = ProductSort(UserSort[])
equalSorts(a::ProductSort, b::ProductSort) = a.ae == b.ae


"""
$(TYPEDEF)
"""
struct CyclicEnumerationSort <: AbstractSort
    # list of feconstant
    ae::Vector{FEConstant} # FiniteEnumerationConstant
end
CyclicEnumerationSort() = CyclicEnumerationSort(FEConstant[])
elements(s::CyclicEnumerationSort) = s.ae
equalSorts(a::CyclicEnumerationSort, b::CyclicEnumerationSort) = a.ae == b.ae

"""
$(TYPEDEF)
"""
struct FiniteEnumerationSort <: AbstractSort
    # list of feconstant
    ae::Vector{FEConstant}
end
FiniteEnumerationSort() = FiniteEnumerationSort(FEConstant[])
equalSorts(a::FiniteEnumerationSort, b::FiniteEnumerationSort) = a.ae == b.ae

"""
$(TYPEDEF)
"""
struct FiniteIntRangeSort{T} <: AbstractSort
    start::T
    stop::T
end
FiniteIntRangeSort() = FiniteIntRangeSort(0, 0)
equalSorts(a::FiniteIntRangeSort, b::FiniteIntRangeSort) = (a.start == b.start && a.stop == b.stop)


"""
$(TYPEDEF)
"""
struct StringSort <: AbstractSort
    #
    ae::Vector{AbstractSort}
end
StringSort() = StringSort(IntegerSort[])
equalSorts(a::StringSort, b::StringSort) = a.ae == b.ae

"""
$(TYPEDEF)
"""
struct ListSort <: AbstractSort
    #
    ae::Vector{AbstractSort}
end
ListSort() = ListSort(IntegerSort[])
equalSorts(a::ListSort, b::ListSort) = a.ae == b.ae


"""
$(TYPEDSIGNATURES)
Return instance of default sort based on `PNTD`.
"""
function default_sort end
default_sort(x::Any) = error("no default sort defined for $(typeof(x))")
default_sort(pntd::PnmlType) = default_sort(typeof(pntd))
default_sort(::Type{<:PnmlType}) = IntegerSort
default_sort(::Type{<:AbstractContinuousNet}) = RealSort
