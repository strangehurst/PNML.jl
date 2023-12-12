"""
$(TYPEDEF)
$(TYPEDFIELDS)

Place node of a Petri Net Markup Language graph.
"""
struct Place{PNTD, M, S<:SortType}  <: AbstractPnmlNode{PNTD}
    pntd::PNTD
    id::Symbol
    #!marking::M
    initialMarking::M
    sorttype::S
    name::Maybe{Name}
    graphics::Maybe{Graphics}
    tools::Vector{ToolInfo}
    labels::Vector{PnmlLabel}
end

nettype(::Place{T}) where {T <: PnmlType} = T
initial_marking(place::Place) = place.initialMarking
default_marking(place::Place) = default_marking(place.pntd)

function Base.show(io::IO, place::Place)
    print(io, nameof(typeof(place)), "(")
    show(io, pid(place)); print(io, ", ")
    show(io, name(place)); print(io, ", ")
    show(io, place.sorttype); print(io, ", ")
    show(io, initial_marking(place));
    print(io, ")")
end

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
    graphics::Maybe{Graphics}
    tools::Vector{ToolInfo}
    labels::Vector{PnmlLabel}
end

nettype(::Transition{T}) where {T <: PnmlType} = T

"""
Return value of condition.
"""
condition(transition::Transition) = _evaluate(transition.condition)::condition_value_type(nettype(transition))

default_condition(transition::Transition) = default_condition(transition.pntd)

function Base.show(io::IO, trans::Transition)
    print(io, nameof(typeof(trans)),
          " id ", pid(trans), ", name '", name(trans), "'", ", condition ", condition(trans))
end

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
    graphics::Maybe{Graphics}
    tools::Vector{ToolInfo}
    labels::Vector{PnmlLabel}

    function Arc(pntd, i, src, tgt, ins, n, g, t, l)
        inscript = @something(ins, default_inscription(pntd))
        new{typeof(pntd), typeof(inscript)}(pntd, i, src, tgt, inscript, n, g, t, l)
    end
end

Arc(a::Arc, src::Symbol, tgt::Symbol) =
    Arc(a.pntd, a.id, src, tgt, a.inscription, a.name, a.graphics, a.tools, a.labels)

nettype(::Arc{T}) where {T <: PnmlType} = T
inscription(arc::Arc) = _evaluate(arc.inscription)
default_inscription(arc::Arc) = default_inscription(arc.pntd)

"""
    source(arc) -> Symbol

Return identity symbol of source of `arc`.
"""
source(arc::Arc)::Symbol = arc.source

"""
    target(arc) -> Symbol

Return identity symbol of target of `arc`.
"""
target(arc::Arc)::Symbol = arc.target

function Base.show(io::IO, arc::Arc)
    print(io, nameof(typeof(arc)), " id ", arc.id,
          ", name '", has_name(arc) ? name(arc) : "", "'",
          ", source: ", source(arc),
          ", target: ", target(arc),
          ", inscription: ", arc.inscription)
end

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
    graphics::Maybe{Graphics}
    tools::Vector{ToolInfo}
    labels::Vector{PnmlLabel}
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
    graphics::Maybe{Graphics}
    tools::Vector{ToolInfo}
    labels::Vector{PnmlLabel}
end

function Base.show(io::IO, r::ReferenceNode)
    print(io, nameof(typeof(r)), "(", pid(r), ",  ", refid(r), ")")
end
