"""
Place node of a Petri Net Markup Language graph.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct Place{PNTD,MarkingType,SortType} <: PnmlNode{PNTD}
    pntd::PNTD
    id::Symbol
    #
    marking::MarkingType
    initialMarking::MarkingType
    # High-level Petri Nets place's markings have sorts.
    sorttype::SortType # Place type is different from pntd/PnmlType.
    name::Maybe{Name}
    com::ObjectCommon
end

Place(pntd::PnmlType, id::Symbol, marking, sort, name, oc::ObjectCommon) =
    Place{typeof(pntd),
          typeof(marking),
          typeof(sort)}(pntd, id, marking, marking, sort, name, oc)

marking(place) = marking(place.pntd, place)
marking(pntd::PnmlType, place) = isnothing(place.marking) ? default_marking(place) : place.marking
marking(pntd::AbstractHLCore, place) = isnothing(place.marking) ? default_marking(place) : place.marking

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

#! Condition is High-level specific in the specification.
condition(transition) = condition(transition.pntd, transition)
function condition(::PnmlType, transition)
    if isnothing(transition.condition) || isnothing(transition.condition.term)
        default_condition(transition).term
    else
        transition.condition.term
    end
end
function condition(::AbstractHLCore, transition)
    if isnothing(transition.condition) || isnothing(transition.condition.term)
        default_condition(transition).term
    else
        transition.condition.term
        #TODO evaluate condition
        #TODO implement full structure handling
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
        _evaluate(arc.inscription)
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

#RefPlace(pntd::PnmlType, id::Symbol, ref::Symbol, oc::ObjectCommon) =
#    RefPlace{typeof(pntd)}(pntd, id, ref, oc)

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

#RefTransition(pntd::PnmlType, id::Symbol, ref::Symbol, oc::ObjectCommon) =
#    RefTransition{typeof(pntd)}(pntd, id, ref, oc)
