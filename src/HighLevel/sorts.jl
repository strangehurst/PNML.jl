"""
$(TYPEDEF)

Wrap a [`AnyElement`](@ref). Use until specialized/cooked.

From the 'primer': built-in sorts of Symmetric Nets are the following:
  Booleans, range of integers, finite enumerations, cyclic enumerations and dots
"""
struct BuiltInSort <: AbstractSort
    dict::AnyElement
end

"""
$(TYPEDEF)

Wrap a [`AnyElement`](@ref). Use until specialized/cooked.
"""
struct MultisetSort <: AbstractSort
    dict::AnyElement
end

"""
$(TYPEDEF)

Wrap a [`AnyElement`](@ref). Use until specialized/cooked.
Should contain an ordered collection of sorts.
"""
struct ProductSort <: AbstractSort
    dict::AnyElement
end

"""
$(TYPEDEF)

Wrap a [`AnyElement`](@ref). Use until specialized/cooked.
"""
struct UserSort <: AbstractSort
    dict::AnyElement
end


"""
$(TYPEDEF)
$(TYPEDFIELDS)

Part of the many-sorted algebra attached to nodes on a Petri Net Graph.
Is content of a <structure> element of a High-Level label.
"""
struct Sort{T<:AbstractDict}
    tag::Symbol
    dict::T #TODO What should be here?
    #TODO xml
end

Sort() = Sort(:empty, PnmlDict())
Sort(p::Pair{Symbol,PnmlDict}) = Sort(p.first, p.second)
Sort(a::AnyElement) = Sort(a.tag, a.dict)

Base.convert(::Type{Maybe{Sort}}, pdict::PnmlDict)::Sort = Sort(pdict)

sort_type(::Type{<:PnmlType}) = Int
sort_type(::Type{<:AbstractContinuousNet}) = Float64
sort_type(::Type{<:AbstractHLCore}) = Sort{PnmlDict}
