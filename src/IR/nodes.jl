"""
$(TYPEDEF)
$(TYPEDFIELDS)

Place node of a Petri Net Markup Language graph.
"""
mutable struct Place{PNTD,M,S} <: PnmlNode{PNTD}
    pntd::PNTD
    id::Symbol

    marking::M
    initialMarking::M
    # High-level Petri Nets place's markings have sorts.
    sorttype::S # Place type is different from pntd/PnmlType. #! HL
    name::Maybe{Name}
    com::ObjectCommon

    function Place(pntd::PnmlType, id::Symbol, initMarking, sort, name, oc::ObjectCommon)
        marking = isnothing(initMarking) ? default_marking(pntd) : initMarking
        new{typeof(pntd),typeof(marking),typeof(sort)}(pntd, id, marking, initMarking,
                                                       sort, name, oc)
    end
end

marking(place) = place.marking
default_marking(place::Place) = default_marking(place.pntd)

#-------------------
"""
Transition node of a Petri Net Markup Language graph.

$(TYPEDEF)
$(TYPEDFIELDS)


"""
struct Transition{PNTD,C}  <: PnmlNode{PNTD}
    pntd::PNTD
    id::Symbol
    condition::C
    name::Maybe{Name}
    com::ObjectCommon
end

#! Condition is High-level specific in the specification as an expression of the
#! many-sortthated algebra that evaluates to a boolean value.
#! Make others evaluate to true by default.
condition(transition) = condition(transition.pntd, transition)
# While conditions are only defined for high-level nets in the specification,
#
function condition(::PnmlType, transition)
    if isnothing(transition.condition) || isnothing(transition.condition.term)
        default_condition(transition).term #TODO rename term to value?
    else
        transition.condition.term
    end
end

function condition(::AbstractHLCore, transition)
    #TODO evaluate condition.term
    #TODO implement full structure handling
    if isnothing(transition.condition) || isnothing(transition.condition.term)
        default_condition(transition).term
    else
        transition.condition.term
    end
end

default_condition(transition::Transition) = default_condition(transition.pntd)

#-------------------
"""
Edge of a Petri Net Markup Language graph that connects place and transition.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
mutable struct Arc{PNTD,ITYPE} <: PnmlObject{PNTD}
    pntd::PNTD
    id::Symbol
    source::Symbol
    target::Symbol
    inscription::ITYPE #Union{PTInscription,HLInscription}}
    name::Maybe{Name}
    com::ObjectCommon
    #TODO Enforce constraints in constructor? (see ocl in Primer's UML)
end

#
Arc(a::Arc, src::Symbol, tgt::Symbol) =
    Arc(a.pntd, a.id, src, tgt, a.inscription, a.name, a.com)

# This is evaluating the inscription attached to an arc.
# Original implementation is for PTNet.
# HLPNGs should do usual label semantics  here.
inscription(arc) = inscription(arc.pntd, arc)
function inscription(::PnmlType, arc)
    if !isnothing(arc.inscription)
        _evaluate(arc.inscription)
    else
        _evaluate(default_inscription(arc))
    end
end
function inscription(::AbstractHLCore, arc)
    if !isnothing(arc.inscription)
        _evaluate(arc.inscription) #TODO term?
    else
        _evaluate(default_inscription(arc))
    end
end
default_inscription(arc::Arc) = default_inscription(arc.pntd)

"""
$(TYPEDSIGNATURES)

Return symbol of source of `arc`.
"""
source(arc)::Symbol = arc.source

"""
$(TYPEDSIGNATURES)

Return symbol of target of `arc`.
"""
target(arc)::Symbol = arc.target

#-------------------
"""
Reference Place node of a Petri Net Markup Language graph. For connections between pages.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct RefPlace{PNTD} <: ReferenceNode{PNTD}
    pntd::PNTD
    id::Symbol
    ref::Symbol # Place or RefPlace
    name::Maybe{Name}
    com::ObjectCommon
    #TODO Enforce constraints in constructor? (see ocl in Primer's UML)
end

#-------------------
"""
Refrence Transition node of a Petri Net Markup Language graph. For connections between pages.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct RefTransition{PNTD} <: ReferenceNode{PNTD}
    pntd::PNTD
    id::Symbol
    ref::Symbol # Transition or RefTransition
    name::Maybe{Name}
    com::ObjectCommon
    #TODO Enforce constraints in constructor? (see ocl in Primer's UML)
end
