"""
Return default condition based on `PNTD`. Has meaning of true or always.
"""
function default_condition end
default_condition(::PNTD) where {PNTD <: PnmlType} = Condition(true)
default_condition(::Type{PNTD}) where {PNTD <: PnmlType} = Condition(true)
default_condition(::PNTD) where {PNTD <: AbstractContinuousCore} = Condition(true)
default_condition(::Type{PNTD}) where {PNTD <: AbstractContinuousCore} = Condition(true)
default_condition(pntd::PNTD) where {PNTD <: AbstractHLCore} = Condition(default_term(pntd)) #!
default_condition(::Type{PNTD}) where {PNTD <: AbstractHLCore} = Condition(default_term(PNTD)) #!

"""
Label of a Transition that determines when the transition fires.

$(TYPEDEF)
$(TYPEDFIELDS)
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

