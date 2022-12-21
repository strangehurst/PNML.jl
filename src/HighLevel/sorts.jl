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
Return instance of default sort based on `PNTD`. Has meaning of empty, as in `zero`.
"""
function default_sort end

default_sort(::PnmlType)              = zero(Integer) #!
default_sort(::AbstractContinuousNet) = zero(Float64) #!
default_sort(::AbstractHLCore)        = Sort() #!

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Part of the many-sorted algebra attached to nodes on a Petri Net Graph.
Is content of a <structure> element of a High-Level label.
"""
struct Sort #TODO
    dict::PnmlDict #TODO AnyElement for bring-up? What should be here?
    #TODO xml
end

Sort() = Sort(PnmlDict())
convert(::Type{Maybe{Sort}}, pdict::PnmlDict) = Sort(pdict)
