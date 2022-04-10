"""
Return default  based on `PNTD`. Has meaning of empty, as in `zero`.
"""
function default_sort end
default_sort(::PNTD) where {PNTD <: PnmlType} = zero(Integer) #!
default_sort(::PNTD) where {PNTD <: AbstractContinuousCore} = zero(Float64) #!
default_sort(::PNTD) where {PNTD <: AbstractHLCore} = Sort() #!

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Part of the many-sorted algebra attached to nodes on a Petri Net Graph.
"""
struct Sort #TODO 
    dict::PnmlDict #TODO AnyElement for bring-up? What should be here?
    #TODO xml
end

Sort() = Sort(PnmlDict())
convert(::Type{Maybe{Sort}}, pdict::PnmlDict) = Sort(pdict)
