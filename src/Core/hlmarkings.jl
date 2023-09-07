"""
Label of a `Place` in a High-level Petri Net Graph.
See [`AbstractHLCore`](@ref), [`Term`](@ref).

Multisets of a sort.

$(TYPEDEF)
$(TYPEDFIELDS)

# Examples

```jldoctest; setup=:(using PNML; using PNML: HLMarking, Term)
julia> m = HLMarking("the text", Term(:value, 3))
HLMarking("the text", Term(:value, 3), nothing, [])

julia> m()
3
```
"""
struct HLMarking{T <: AbstractTerm} <: HLAnnotation
    text::Maybe{String} # Supposed to be for human consumption.
    term::T # Content of <structure> must be a many-sorted algebra term.
    graphics::Maybe{Graphics}
    tools::Vector{ToolInfo}
end

HLMarking(t::AbstractTerm)   = HLMarking(nothing, t)
HLMarking(s::Maybe{AbstractString}, t::Maybe{AbstractTerm}) = HLMarking(s, t, nothing, ToolInfo[])

value(m::HLMarking) = m.term

#! HLMarking is a multiset, not an expression.
"""
$(TYPEDSIGNATURES)
Evaluate a [`HLMarking`](@ref) instance by returning its term.
"""
(hlm::HLMarking)() = _evaluate(value(hlm))
#TODO convert to sort
#TODO query sort

marking_type(::Type{T}) where {T<:AbstractHLCore} = HLMarking{Term}
marking_value_type(::Type{<:AbstractHLCore}) = eltype(DotSort())
