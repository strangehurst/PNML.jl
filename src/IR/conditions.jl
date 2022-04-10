"""
Return default condition based on `PNTD`. Has meaning of true or always.
"""
function default_condition end
default_condition(::PNTD) where {PNTD <: PnmlType} = true
default_condition(::PNTD) where {PNTD <: AbstractContinuousCore} = true
default_condition(pntd::PNTD) where {PNTD <: AbstractHLCore} = default_term(pntd) #!

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
Condition(text::AbstractString, value) = Condition(text, value, ObjectCommon())
Condition(text::AbstractString, value, oc::ObjectCommon) = Condition{typeof(value)}(text, value, oc)
