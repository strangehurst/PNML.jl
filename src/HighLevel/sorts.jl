"""
$(TYPEDEF)

Wrap a [`AnyElement`](@ref). Use until specialized/cooked.

From the 'primer': built-in sorts of Symmetric Nets are the following:
  Booleans, range of integers, finite enumerations, cyclic enumerations and dots
"""
struct BuiltInSort <: AbstractSort
    ae::AnyElement
end

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
    ae::AnyElement
end

"""
$(TYPEDEF)

Wrap a [`AnyElement`](@ref). Use until specialized/cooked.
"""
struct UserSort <: AbstractSort
    ae::AnyElement
end


"""
$(TYPEDEF)
$(TYPEDFIELDS)

Part of the many-sorted algebra of a High-level Petri Net Graph.
A label whose <structure> element holds an [`AbstractSort`](@ref) term.
"""
struct SortType{T <: Term} <: HLAnnotation
    text::Maybe{String} # Supposed to be for human consumption.
    sort::T # Content of <structure> must be a many-sorted algebra term.
    com::ObjectCommon
    #TODO xml
end
# TODO TBD Define a `SortType` interface.text(i::HLInscription)  = i.text

#! SortType() = SortType(nothing, Term(), ObjectCommon())
SortType(t::Term) = SortType(nothing, t, ObjectCommon())
SortType(s::AbstractString, t::Term) = SortType(s, t, ObjectCommon())

Base.convert(::Type{Maybe{SortType}}, tup::NamedTuple)::SortType = SortType(tup)

text(t::SortType)  = t.text
value(t::SortType) = t.sort
common(t::SortType) = t.com

sort_type(::Type{<:PnmlType}) = Int
sort_type(::Type{<:AbstractContinuousNet}) = Float64
sort_type(::Type{<:AbstractHLCore}) = typeof(SortType(Term())) #! Should be AbstractSort Term
