"""
Place node of a Petri Net Markup Language graph.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct Place <: PnmlNode
    id::Symbol
    marking::Maybe{Union{PTMarking,HLMarking}} #TODO remove Maybe, add initialMarking
    sorttype::Maybe{PnmlLabel} # Place type is different from pntd/PnmlType.

    com::ObjectCommon
end

Place(pdict::PnmlDict) =
    Place(pdict[:id], pdict[:marking], pdict[:type], ObjectCommon(pdict))

#-------------------
"""
Transition node of a Petri Net Markup Language graph.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct Transition <: PnmlNode
    id::Symbol
    condition::Maybe{Condition}

    com::ObjectCommon
end

Transition(pdict::PnmlDict) =
    Transition(pdict[:id], pdict[:condition], ObjectCommon(pdict))

#-------------------
"""
Edge of a Petri Net Markup Language graph that connects place and transition.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
mutable struct Arc <: PnmlObject
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
Arc(pdict::PnmlDict) =
    Arc(pdict[:id], pdict[:source], pdict[:target], pdict[:inscription], ObjectCommon(pdict))

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
struct RefPlace <: PnmlNode
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
struct RefTransition <: PnmlNode
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

