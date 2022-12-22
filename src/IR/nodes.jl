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
        initmark = isnothing(initMarking) ? default_marking(pntd) : initMarking
        new{typeof(pntd),typeof(initmark),typeof(sort)}(pntd, id, initmark, initmark,
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

    function Transition(pntd, i, c, n, com)
        condition = isnothing(c) ? default_condition(pntd) : c
        new{typeof(pntd), typeof(condition)}(pntd, i, condition, n, com)
    end
end

condition(transition) = transition.condition()

default_condition(transition::Transition) = default_condition(transition.pntd)

#-------------------
"""
Edge of a Petri Net Markup Language graph that connects place and transition.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
mutable struct Arc{PNTD,I} <: PnmlObject{PNTD}
    pntd::PNTD
    id::Symbol
    source::Symbol
    target::Symbol
    inscription::I
    name::Maybe{Name}
    com::ObjectCommon

    function Arc(pntd, i, src, tgt, ins, n, c)
        inscript = isnothing(ins) ? default_inscription(pntd) : ins
        new{typeof(pntd), typeof(inscript)}(pntd, i, src, tgt, inscript, n, c)
    end
end

Arc(a::Arc, src::Symbol, tgt::Symbol) =
    Arc(a.pntd, a.id, src, tgt, a.inscription, a.name, a.com)

inscription(arc) = _evaluate(arc.inscription)

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
end
