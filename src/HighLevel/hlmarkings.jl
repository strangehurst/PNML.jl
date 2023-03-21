"""
Label of a `Place` in a High-level Petri Net Graph.
See [`AbstractHLCore`](@ref), [`Term`](@ref).

Multisets of a sort.

$(TYPEDEF)
$(TYPEDFIELDS)

# Examples

```jldoctest; setup=:(using PNML; using PNML: HLMarking, PnmlDict, Term)
julia> m = HLMarking("the text", Term(:term, PnmlDict(:value=>3)))
HLMarking("the text", Term(:term, OrderedCollections.OrderedDict{Symbol, Any}(:value => 3)), )

julia> PnmlDict
OrderedCollections.OrderedDict{Symbol, Any}

julia> m()
3
```
"""
struct HLMarking{T} <: HLAnnotation
    text::Maybe{String} # Supposed to be for human consumption.
    "Any <structure> must be a many-sorted algebra term for a <hlmarking>."
    term::T
    com::ObjectCommon
    #TODO check that there is a text or structure (or both)
end

HLMarking() = HLMarking(nothing, nothing)
HLMarking(s::AbstractString) = HLMarking(s, nothing)
HLMarking(t::Any) = HLMarking(nothing, t, ObjectCommon())
HLMarking(s::AbstractString, t::Any) = HLMarking(s, t, ObjectCommon())

value(m::HLMarking) = m.term
common(m::HLMarking) = m.com

#! HLMarking is a multiset, not an expression.
"""
$(TYPEDSIGNATURES)
Evaluate a [`HLMarking`](@ref) instance by returning its term.
"""
(hlm::HLMarking)() = _evaluate(value(hlm))
#TODO convert to sort
#TODO query sort

marking_type(::Type{T}) where {T<:AbstractHLCore} = HLMarking{Term{PnmlDict}}
marking_value_type(::Type{T}) where {T<:AbstractHLCore} = Int

condition_value_type(::Type{<:AbstractHLCore}) = Bool #Term{PnmlDict} #! RELOCATE for HL
