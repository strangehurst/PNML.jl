"""
Return default condition based on `PNTD`. Has meaning of true or always.

# Examples

```jldoctest; setup=:(using PNML; using PNML: default_condition)
julia> m = default_condition(PnmlCore())
Condition(nothing, true, )

julia> m = default_condition(ContinuousNet())
Condition(nothing, true, )

julia> m = default_condition(HLCore())
Condition(nothing, true, )
```
"""
function default_condition end
default_condition(::PNTD) where {PNTD <: PnmlType} = Condition(true)
default_condition(::Type{PNTD}) where {PNTD <: PnmlType} = Condition(true)
default_condition(::PNTD) where {PNTD <: AbstractContinuousCore} = Condition(true)
default_condition(::Type{PNTD}) where {PNTD <: AbstractContinuousCore} = Condition(true)
default_condition(pntd::PNTD) where {PNTD <: AbstractHLCore} = Condition(true)#default_term(pntd)) #!
default_condition(::Type{PNTD}) where {PNTD <: AbstractHLCore} = Condition(true)

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
    term::T # structure
    com::ObjectCommon 

end
Condition() = Condition(nothing, true, ObjectCommon())
Condition(value) = Condition(nothing, value, ObjectCommon())
Condition(text, value) = Condition(text, value, ObjectCommon())
Condition(text, value, oc::ObjectCommon) = Condition{typeof(value)}(text, value, oc)
Condition(::Nothing) =  error("Condition must have a `value`, ")
Condition(::Maybe{String}, ::Nothing) = error("Condition must have a `value`, ")
Condition(::Maybe{String}, ::Nothing, ::ObjectCommon) = error("Condition must have a `value`, ")

"""
Evaluate a [`Condition`](@ref) instance.
"""
(mark::Condition)() = _evaluate(mark.term)
