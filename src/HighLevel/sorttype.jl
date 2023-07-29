"""
$(TYPEDEF)
$(TYPEDFIELDS)

A places's <type> label's <structure> element holds a concrete subtype of [`AbstractSort`](@ref).
Defines the sort of a place, hence use of `sorttype`.

For high-level nets there will be a rich language of sorts.

Here type means a term from the many-sorted algebra.
We use sorts even for non-high-level nets. Use `eltype(::DotSort())` the underlying type.
"""
struct SortType{T <: AbstractSort} # <: AbstractLabel
    text::Maybe{String} # Supposed to be for human consumption.
    sort::T # Content of high-level <structure>.
    com::ObjectCommon
    #TODO xml
end
# TODO TBD Define a `SortType` interface.text(i::HLInscription)  = i.text

SortType(t::AbstractSort) = SortType(nothing, t, ObjectCommon())
SortType(s::AbstractString, t::AbstractSort) = SortType(s, t, ObjectCommon())

text(t::SortType)  = t.text
value(t::SortType) = t.sort
common(t::SortType) = t.com
Base.eltype(::SortType{T}) where {T} = eltype(T) # Look a layer deeper.
