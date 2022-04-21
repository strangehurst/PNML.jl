"""
Return default marking value based on `PNTD`. Has meaning of empty, as in `zero`.
"""
function default_marking end
default_marking(::PNTD) where {PNTD <: PnmlType} = zero(Integer)
default_marking(::PNTD) where {PNTD <: AbstractContinuousCore} = zero(Float64)
default_marking(pntd::PNTD) where {PNTD <: AbstractHLCore} = default_term(pntd) #!

#-------------------
"""
Number-valued label of [`Place`](@ref).
See [`PTNet`](@ref), [`ContinuousNet`](@ref).

$(TYPEDEF)
$(TYPEDFIELDS)

# Examples

```jldoctest
julia> using PNML

julia> m = PNML.PTMarking();

julia> m()
0

julia> m = PNML.PTMarking(1);

julia> m()
1

julia> m = PNML.PTMarking(12.34);

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
Evaluate a [`PTMarking`](@ref) instance.
"""
(mark::PTMarking)() = mark.value

#-------------------
"""
Label a Place in a High-level Petri Net Graph.
See [`AbstractHLCore`](#ref).

$(TYPEDEF)
$(TYPEDFIELDS)

# Examples

```jldoctest
julia> using PNML: HLMarking, PnmlDict, Term

julia> m = HLMarking("the text", Term(:term, PnmlDict(:value=>3)));

julia> m()
"HLMarking functor not implemented"
```
"""
struct HLMarking{TermType} <: HLAnnotation
    text::Maybe{String}
    term::Maybe{TermType} # is the expected structure content
    com::ObjectCommon
    #TODO check that there is a text or structure (or both)
end

HLMarking() = HLMarking(nothing, Term())
HLMarking(s::AbstractString) = HLMarking(s, Term())
HLMarking(t::AbstractTerm) = HLMarking(nothing, t)
HLMarking(s::AbstractString, t::AbstractTerm) = HLMarking(s, t, ObjectCommon())

"""
Evaluate a [`HLMarking`](@ref) instance. 
Returns a value of the same sort as its `Place`.
"""
(hlm::HLMarking)() = "HLMarking functor not implemented"

