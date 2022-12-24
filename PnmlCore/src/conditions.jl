"""
Label of a Transition that determines when the transition fires.

$(TYPEDEF)
$(TYPEDFIELDS)

# Examples

```jldoctest; setup=:(using PNML; using PNML: Condition)
julia> c = Condition(PnmlCoreNet())
Condition(nothing, true, )

julia> c()
true

julia> c = Condition(PnmlCoreNet(), false)
Condition(nothing, false, )

julia> c()
false

julia> c = Condition(PnmlCoreNet(), "xx", false)
Condition("xx", false, )

julia> c()
false
```
"""
mutable struct Condition{PNTD,T} <: Annotation
    pntd::PNTD
    text::Maybe{String}
    term::T #! Rexname to value.
    com::ObjectCommon

    function Condition(pntd, t, v, c)
        val = isnothing(v) ? default_condition(pntd) : v
        new{typeof(pntd), typeof(val)}(pntd, t, val, c)
    end
end

Condition(pntd) = Condition(pntd, nothing, true, ObjectCommon())
Condition(pntd, value) = Condition(pntd, nothing, value, ObjectCommon())
Condition(pntd, text, value) = Condition(pntd, text, value, ObjectCommon())

value(c::Condition) = c.term
common(c::Condition) = c.com
"""
$(TYPEDSIGNATURES)
Evaluate a [`Condition`](@ref) instance.
"""
(c::Condition)() = _evaluate(value(c))
