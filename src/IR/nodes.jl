"""
Place node of a Petri Net Markup Language graph.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct Place{PnmlType,MarkingType,SortType} <: PnmlNode
    id::Symbol
    #
    marking::Maybe{MarkingType} #TODO default marking when initialMarking is nothing.
    initialMarking::Maybe{MarkingType} #TODO
    # High-level Petri Nets place's have sorts.
    sorttype::Maybe{SortType} # Place type is different from pntd/PnmlType.

    com::ObjectCommon
end

Place(pd::PnmlDict, pntd::PnmlType = PnmlCore()) =
    Place{typeof(pntd),
         typeof(pd[:marking]),
         typeof(pd[:type])}(pd[:id], pd[:marking], pd[:marking], pd[:type], ObjectCommon(pd))

#-------------------
"""
Transition node of a Petri Net Markup Language graph.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct Transition{PnmlType}  <: PnmlNode
    id::Symbol
    condition::Maybe{Condition}

    com::ObjectCommon
end

Transition(pdict::PnmlDict, pntd::PnmlType = PnmlCore()) =
    Transition{typeof(pntd)}(pdict[:id], pdict[:condition], ObjectCommon(pdict))

#-------------------
"""
Edge of a Petri Net Markup Language graph that connects place and transition.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
mutable struct Arc{PnmlType} <: PnmlObject
    id::Symbol
    source::Symbol
    target::Symbol
    inscription::Maybe{Union{PTInscription,HLInscription}}
    com::ObjectCommon
    #TODO Enforce constraints in constructor? (see ocl in Primer's UML)
end

"""
$(TYPEDSIGNATURES)
"""
Arc(pdict::PnmlDict, pntd::PnmlType = PnmlCore()) =
    Arc{typeof(pntd)}(pdict[:id], pdict[:source], pdict[:target], pdict[:inscription], ObjectCommon(pdict))

"""
$(TYPEDSIGNATURES)
"""
Arc(a::Arc, src::Symbol, tgt::Symbol) = Arc(a.id, src, tgt, a.inscription, a.com)

#-------------------
"""
Reference Place node of a Petri Net Markup Language graph. For connections between pages.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct RefPlace <: ReferenceNode
    id::Symbol
    ref::Symbol # Place or RefPlace
    com::ObjectCommon
    #TODO Enforce constraints in constructor? (see ocl in Primer's UML)
end

RefPlace(pdict::PnmlDict) = RefPlace(pdict[:id], pdict[:ref], ObjectCommon(pdict))

#-------------------
"""
Refrence Transition node of a Petri Net Markup Language graph. For connections between pages.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct RefTransition <: ReferenceNode
    id::Symbol
    ref::Symbol # Transition or RefTransition
    com::ObjectCommon
    #TODO Enforce constraints in constructor? (see ocl in Primer's UML)
end

"""
$(TYPEDSIGNATURES)
"""
RefTransition(pdict::PnmlDict) =
    RefTransition(pdict[:id], pdict[:ref], ObjectCommon(pdict))
