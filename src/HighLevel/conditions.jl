"""
Label of a Transition that determines when the transition fires.

$(TYPEDEF)
$(TYPEDFIELDS)

# Examples

```jldoctest; setup=:(using PNML; using PNML: Condition, HLMarking, Term)
julia> c = Condition()
Condition(nothing, true, )

julia> c()
true

julia> c = Condition(false)
Condition(nothing, false, )

julia> c()
false

julia> c = Condition("xx", false)
Condition("xx", false, )

julia> c()
false
```
"""
struct Condition{T} <: HLAnnotation
    text::Maybe{String}
    term::T # <structure> tag will contain a term.
    com::ObjectCommon

end
Condition() = Condition(nothing, true, ObjectCommon())
Condition(value) = Condition(nothing, value, ObjectCommon())
Condition(text, value) = Condition(text, value, ObjectCommon())

Condition(::Nothing) =  error("Condition must have a `value`, ")
Condition(::Maybe{String}, ::Nothing) = error("Condition must have a `value`, ")
Condition(::Maybe{String}, ::Nothing, ::ObjectCommon) = error("Condition must have a `value`, ")

"""
$(TYPEDSIGNATURES)
Evaluate a [`Condition`](@ref) instance.
"""
(c::Condition)() = _evaluate(c.term)
