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

_evaluate(x::AbstractSort) = x() # functor

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
Are the sorts `eltype` the same?
"""
equals(a::AbstractSort, b::AbstractSort) = eltype(a) == eltype(b)

"""
$(TYPEDEF)

Wrap a [`AnyElement`](@ref). Use until specialized/cooked.
"""
struct MultisetSort <: AbstractSort
    ae::AnyElement
end

"""
$(TYPEDEF)

Wrap a [`AnyElement`](@ref). Use until specialized/cooked.
Should contain an ordered collection of sorts.
"""
struct ProductSort <: AbstractSort
    ae::AnyElement # Vector{AbstractSort}
end

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
