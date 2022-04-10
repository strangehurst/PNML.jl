"""
Place node of a Petri Net Markup Language graph.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct Place{PNTD<:PnmlType,MarkingType,SortType} <: PnmlNode
    pntd::PNTD
    id::Symbol
    #
    marking::Maybe{MarkingType} #TODO default marking when initialMarking is nothing.
    initialMarking::Maybe{MarkingType} #TODO
    # High-level Petri Nets place's have sorts.
    sorttype::Maybe{SortType} # Place type is different from pntd/PnmlType.

    com::ObjectCommon
end
#TODO marking/sort types from pntd when nothing
Place(pntd::PNTD, id::Symbol, marking, sort, oc::ObjectCommon) where {PNTD<:PnmlType} =
    Place{typeof(pntd), typeof(marking), typeof(sort)}(pntd, id, marking, marking, sort, oc)

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

    com::ObjectCommon
end

Transition(pntd::PNTD, id::Symbol, condition, oc::ObjectCommon) where {PNTD<:PnmlType} =
    Transition{typeof(pntd),typeof(condition)}(pntd, id, condition. oc)

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
    com::ObjectCommon
    #TODO Enforce constraints in constructor? (see ocl in Primer's UML)
end

Arc(pntd::PNTD, id::Symbol, src::Symbol, tgt::Symbol, 
        inscription, oc::ObjectCommon) where {PNTD<:PnmlType} =
    Arc{typeof(pntd),typeof(inscription)}(pntd, id, src, tgt, inscription, oc)


"""
$(TYPEDSIGNATURES)
"""
Arc(a::Arc, src::Symbol, tgt::Symbol) = Arc(a.pntd, a.id, src, tgt, a.inscription, a.com)

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
    com::ObjectCommon
    #TODO Enforce constraints in constructor? (see ocl in Primer's UML)
end

RefPlace(pntd::PNTD, id::Symbol, ref::Symbol, oc::ObjectCommon) where {PNTD<:PnmlType} =
    RefPlace{typeof(pntd)}(pntd, id, ref, oc)

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
    com::ObjectCommon
    #TODO Enforce constraints in constructor? (see ocl in Primer's UML)
end

RefTransition(pntd::PNTD, id::Symbol, ref::Symbol, oc::ObjectCommon) where {PNTD<:PnmlType} =
    RefTransition{typeof(pntd)}(pntd, id, ref, oc)
