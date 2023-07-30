"""
$(TYPEDEF)
$(TYPEDFIELDS)

A places's <type> label's <structure> element holds a concrete subtype of [`AbstractSort`](@ref).
Defines the sort of a place, hence use of `sorttype`.

For high-level nets there will be a rich language of sorts using [`UserSort`](@ref)
and [`NamedSort`](@ref).

Notes:
- `NamedSort` is a [`SortDeclaration`](@ref). [`HLPNG`](@ref) adds [`ArbitrarySort`](@ref).
- `UserSort` holds the id symbol of a `NamedSort`.
- Here 'type' means a 'term' from the many-sorted algebra.
- We use sorts even for non-high-level nets for type-stability.
- Expect `eltype(::AbstractSort)` to return a concrete subtype of `Number`.
"""
struct SortType{T <: AbstractSort} # <: AbstractLabel
    text::Maybe{String} # Supposed to be for human consumption.
    sort::T # Content of high-level <structure>.
    com::ObjectCommon
end

SortType(t::AbstractSort) = SortType(nothing, t, ObjectCommon())
SortType(s::AbstractString, t::AbstractSort) = SortType(s, t, ObjectCommon())

text(t::SortType)  = t.text
value(t::SortType) = t.sort
common(t::SortType) = t.com

type(::SortType{T}) where {T} = T # Look a layer deeper.
