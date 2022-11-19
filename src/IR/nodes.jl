# Interface methods for abstract types.
xmlnode(node::PnmlNode) = node.xml
refid(reference::ReferenceNode) = reference.ref

"""
Place node of a Petri Net Markup Language graph.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct Place{PNTD<:PnmlType,MarkingType,SortType} <: PnmlNode
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

Place(pntd::PNTD, id::Symbol, marking, sort, name, oc::ObjectCommon) where {PNTD<:PnmlType} =
    Place{typeof(pntd), typeof(marking), typeof(sort)}(pntd, id, marking, marking, sort, name, oc)

# Evaluate the marking.
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
struct Transition{PNTD<:PnmlType,C}  <: PnmlNode
    pntd::PNTD
    id::Symbol
    condition::C
    name::Maybe{Name}
    com::ObjectCommon
end

#! Split out High-level specific version
#! Use traits? 
function condition(transition)
    if isnothing(transition.condition) || isnothing(transition.condition.term)
        default_condition(transition).term #! _evaluate
    else
        transition.condition.term #! _evaluate
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
mutable struct Arc{PNTD<:PnmlType,ITYPE} <: PnmlObject
    pntd::PNTD
    id::Symbol
    source::Symbol
    target::Symbol
    inscription::ITYPE #Union{PTInscription,HLInscription}}
    name::Maybe{Name}
    com::ObjectCommon
    #TODO Enforce constraints in constructor? (see ocl in Primer's UML)
end

#Arc(pntd::PNTD, id::Symbol, src::Symbol, tgt::Symbol, 
#        inscription, oc::ObjectCommon) where {PNTD<:PnmlType} =
#    Arc{typeof(pntd),typeof(inscription)}(pntd, id, src, tgt, inscription, oc)

Arc(a::Arc, src::Symbol, tgt::Symbol) = Arc(a.pntd, a.id, src, tgt, a.inscription, a.name, a.com)

# This is evaluating the incscription attached to an arc.
# Original implementation is for PTNet.
# HLPNGs do usual label semantics  here.
# TODO: Map from net.type to inscription
function inscription(arc)
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
struct RefPlace{PNTD<:PnmlType} <: ReferenceNode
    pntd::PNTD
    id::Symbol
    ref::Symbol # Place or RefPlace
    name::Maybe{Name}
    com::ObjectCommon
    #TODO Enforce constraints in constructor? (see ocl in Primer's UML)
end

#RefPlace(pntd::PNTD, id::Symbol, ref::Symbol, oc::ObjectCommon) where {PNTD<:PnmlType} =
#    RefPlace{typeof(pntd)}(pntd, id, ref, oc)

#-------------------
"""
Refrence Transition node of a Petri Net Markup Language graph. For connections between pages.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct RefTransition{PNTD<:PnmlType} <: ReferenceNode
    pntd::PNTD
    id::Symbol
    ref::Symbol # Transition or RefTransition
    name::Maybe{Name}
    com::ObjectCommon
    #TODO Enforce constraints in constructor? (see ocl in Primer's UML)
end

#RefTransition(pntd::PNTD, id::Symbol, ref::Symbol, oc::ObjectCommon) where {PNTD<:PnmlType} =
#    RefTransition{typeof(pntd)}(pntd, id, ref, oc)
