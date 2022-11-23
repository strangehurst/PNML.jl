"""
Label of a `Place` in a High-level Petri Net Graph.
See [`AbstractHLCore`](@ref), [`Term`](@ref).

Multisets of a sort.

$(TYPEDEF)
$(TYPEDFIELDS)

# Examples

```jldoctest; setup=:(using PNML; using PNML: HLMarking, PnmlDict, Term)
julia> m = HLMarking("the text", Term(:term, PnmlDict(:value=>3)))
HLMarking("the text", Term(:term, Dict(:value => 3)), )

julia> m()
3
```
"""
struct HLMarking{TermType} <: HLAnnotation
    text::Maybe{String} # Supposed to be for human consumption.
    "Any <structure> must be a many-sorted algebra term for a <hlmarking> annotation label."
    term::Maybe{TermType} # Expected structure content.
    com::ObjectCommon
    #TODO check that there is a text or structure (or both)
end

HLMarking() = HLMarking(nothing, Term())
HLMarking(s::AbstractString) = HLMarking(s, Term())
HLMarking(t::AbstractTerm) = HLMarking(nothing, t, ObjectCommon())
HLMarking(s::AbstractString, t::AbstractTerm) = HLMarking(s, t, ObjectCommon())

#! HLMarking is a multiset, not an expression.
"""
$(TYPEDSIGNATURES)
Evaluate a [`HLMarking`](@ref) instance by returning its term.
"""
(hlm::HLMarking)() = _evaluate(hlm.term)

#TODO convert to sort
#TODO query sort
