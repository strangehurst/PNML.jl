"""
$(TYPEDEF)

Wrap a [`AnyElement`](@ref). Use until specialized/cooked.

From the 'primer': built-in sorts of Symmetric Nets are the following:
Booleans, range of integers, finite enumerations, cyclic enumerations and dots.

NB: The pnml specification treats BuiltInSort as an abstract UML2 type. We provide a
concrete type for un-implemented sorts.
"""
struct BuiltInSort <: AbstractSort end
Base.eltype(::BuiltInSort) = AnyXmlNode

struct BoolSort <: AbstractSort end
Base.eltype(::BoolSort) = Bool

struct DotSort <: AbstractSort end
Base.eltype(::DotSort) = Int

"""
$(TYPEDSIGNATURES)
Are the sorts `eltype` the same?
"""
equals(a::AbstractSort, b::AbstractSort) = eltype(a) == eltytpe(b)

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

#TODO NamedSort name, id of a sort

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Part of the many-sorted algebra of a High-level Petri Net Graph.
A label whose <structure> element holds an [`AbstractSort`](@ref) concrete subtype for high-level nets.

"""
struct SortType{T <: AbstractTerm} <: HLAnnotation
    text::Maybe{String} # Supposed to be for human consumption.
    sort::T # Content of <structure> must be a many-sorted algebra term.
    com::ObjectCommon
    #TODO xml
end
# TODO TBD Define a `SortType` interface.text(i::HLInscription)  = i.text

SortType(t::AbstractTerm) = SortType(nothing, t, ObjectCommon())
SortType(s::AbstractString, t::AbstractTerm) = SortType(s, t, ObjectCommon())

text(t::SortType)  = t.text
value(t::SortType) = t.sort
common(t::SortType) = t.com

sort_type(::Type{<:PnmlType}) = Int
sort_type(::Type{<:AbstractContinuousNet}) = Float64
sort_type(::Type{<:AbstractHLCore}) = eltype(DotSort()) #! Should be AbstractSort Term
