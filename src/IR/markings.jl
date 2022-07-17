"""
Return default marking value based on `PNTD`. Has meaning of empty, as in `zero`.

# Examples

```jldoctest; setup=:(using PNML; using PNML: default_marking, PTMarking, HLMarking, pnmltype)
julia> m = default_marking(pnmltype(PnmlCore()))
PTMarking(0, )

julia> m()
0

julia> m = default_marking(typeof(pnmltype(PnmlCore())))
PTMarking(0, )

julia> m()
0

julia> m = default_marking(pnmltype(HLCore()))
HLMarking(nothing, Term(:empty, Dict(:value => 0)), )

julia> m()
0
```
"""
function default_marking end
default_marking(::PNTD) where {PNTD <: PnmlType} = PTMarking(zero(Integer))
default_marking(::Type{PNTD}) where {PNTD <: PnmlType} = PTMarking(zero(Integer))
default_marking(::PNTD) where {PNTD <: AbstractContinuousCore} = PTMarking(zero(Float64))
default_marking(::Type{PNTD}) where {PNTD <: AbstractContinuousCore} = PTMarking(zero(Float64))
default_marking(pntd::PNTD) where {PNTD <: AbstractHLCore} = HLMarking(default_zero_term(pntd))

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
Evaluate a [`HLMarking`](@ref) instance. 
Returns a value of the same sort as its `Place`.
#TODO How to ensure sort type?
"""
(hlm::HLMarking)() = _evaluate(hlm.term)

"""
Inscriptions, Markings, Conditions evaluate a value
that may be a scalar or a [`Term`](@ref) functor.

# Examples

```jldoctest; setup=(using PNML: _evaluate, Term)
julia> _evaluate(1)
1

julia> _evaluate(true)
true

julia> _evaluate(Term(:term, Dict(:value => 3)))
3
```
"""
function _evaluate end
_evaluate(x::Number) = x
_evaluate(x::Bool) = x
_evaluate(x::Term) = x()


