"""
$(TYPEDEF)
$(TYPEDFIELDS)

Place node of a Petri Net Markup Language graph.
"""
struct Place{PNTD,M,S}  <: AbstractPnmlNode{PNTD}
    pntd::PNTD
    id::Symbol

    marking::M
    initialMarking::M
    # High-level Petri Net place's have sorts with meaning, others TBD.
    sorttype::S
    name::Maybe{Name}
    com::ObjectCommon

end

function Place(pntd::PnmlType, id::Symbol, initMarking, sort,
               name::Maybe{Name}, oc::ObjectCommon)
    initmark = something(initMarking, default_marking(pntd))
    Place{typeof(pntd),
          typeof(initmark),
          typeof(sort)}(pntd, id, initmark, initmark, sort, name, oc)
end

nettype(::Place{T}) where {T <: PnmlType} = T

marking(place) = place.marking
default_marking(place::Place) = default_marking(place.pntd)
common(place::Place) = place.com

#-------------------
"""
Transition node of a Petri Net Markup Language graph.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct Transition{PNTD,C}  <: AbstractPnmlNode{PNTD}
    pntd::PNTD
    id::Symbol
    condition::C
    name::Maybe{Name}
    com::ObjectCommon

    function Transition(pntd, i, c, n, com)
        condition = something(c, default_condition(pntd))
        new{typeof(pntd), typeof(condition)}(pntd, i, condition, n, com)
    end
end

nettype(::Transition{T}) where {T <: PnmlType} = T

condition(transition::Transition) = transition.condition()
default_condition(transition::Transition) = default_condition(transition.pntd)
common(t::Transition) = t.com

#-------------------
"""
Edge of a Petri Net Markup Language graph that connects place and transition.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
mutable struct Arc{PNTD,I} <: AbstractPnmlObject{PNTD}
    pntd::PNTD
    id::Symbol
    source::Symbol
    target::Symbol
    inscription::I
    name::Maybe{Name}
    com::ObjectCommon

    function Arc(pntd, i, src, tgt, ins, n, c)
        inscript = something(ins, default_inscription(pntd))
        new{typeof(pntd), typeof(inscript)}(pntd, i, src, tgt, inscript, n, c)
    end
end

Arc(a::Arc, src::Symbol, tgt::Symbol) =
    Arc(a.pntd, a.id, src, tgt, a.inscription, a.name, a.com)

nettype(::Arc{T}) where {T <: PnmlType} = T

inscription(arc) = _evaluate(arc.inscription)
default_inscription(arc::Arc) = default_inscription(arc.pntd)
common(a::Arc) = a.com

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
common(r::RefPlace) = r.com

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
common(r::RefTransition) = r.com
