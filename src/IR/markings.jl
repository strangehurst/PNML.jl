#-------------------
"""
Number-valued label of [`Place`](@ref).
See [`PTNet`](@ref), [`ContinuousNet`](@ref).

Is a functor that returns the `value`.

$(TYPEDEF)
$(TYPEDFIELDS)

# Examples

```jldoctest; setup=:(using PNML: PTMarking)
julia> m = PTMarking()
PTMarking(0, )

julia> m()
0

julia> m = PTMarking(1)
PTMarking(1, )

julia> m()
1

julia> m = PTMarking(12.34)
PTMarking(12.34, )

julia> m()
12.34
```
"""
struct PTMarking{N<:Number} <: Annotation
    value::N
    com::ObjectCommon
    # PTMarking does not use ObjectCommon.graphics,
    # but rather, TokenGraphics in ObjectCommon.tools.
end
PTMarking() = PTMarking(zero(Int))
PTMarking(value) = PTMarking(value, ObjectCommon())

"""
$(TYPEDSIGNATURES)
Evaluate a [`PTMarking`](@ref) instance.
"""
(mark::PTMarking)() = _evaluate(mark.value)

#-------------------
"""
Label of a `Place` in a High-level Petri Net Graph.
See [`AbstractHLCore`](@ref), [`Term`](@ref).
#TODO Term as wrapper of [`PnmlDict`](@ref) should be replaced (someday). 

Is a functor that evaluates the `term`.

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
    text::Maybe{String}
    "Any <structure> must be a many-sorted algebra term for a <hlmarking> annotation label."
    term::Maybe{TermType} # Expected structure content.
    com::ObjectCommon
    #TODO check that there is a text or structure (or both)
end

HLMarking() = HLMarking(nothing, Term())
HLMarking(s::AbstractString) = HLMarking(s, Term())
HLMarking(t::AbstractTerm) = HLMarking(nothing, t, ObjectCommon())
HLMarking(s::AbstractString, t::AbstractTerm) = HLMarking(s, t, ObjectCommon())

"""
$(TYPEDSIGNATURES)
Evaluate a [`HLMarking`](@ref) instance. 
Returns a value of the same sort as its `Place`.
#TODO How to ensure sort type?
"""
(hlm::HLMarking)() = _evaluate(hlm.term)
