"""
$(TYPEDEF)
$(TYPEDFIELDS)

Place node of a Petri Net Markup Language graph.

Each place has an initial marking that has a basis matching sorttype.
M is a "multiset sort denoting a collection of tokens".
A "multiset sort over a basis sort is interpreted as
"the set of multisets over the type associated with the basis sort".
"""
mutable struct Place{PNTD, M}  <: AbstractPnmlNode{PNTD}
    pntd::PNTD
    id::Symbol
    initialMarking::M #^ Marking or HLMarking label that evaluates to a Number or PnmlMultiset.
    # For each place, a sort defines the type of the marking tokens on this place (sorttype).
    # The inscription of an arc to or from a place defines which tokens are added or removed
    # when the corresponding transition fires. These tokens must also be of sorttype.
    sorttype::SortType #^ Label with human text/graphics. And a sort.
    namelabel::Maybe{Name}
    graphics::Maybe{Graphics}
    toolspecinfos::Maybe{Vector{ToolInfo}}
    labels::Maybe{Vector{PnmlLabel}}
    #todo net::PnmlNet
    declarationdicts::DeclDict
end

pntd(p::Place) = p.pntd
nettype(::Place{T}) where {T <: PnmlType} = T

initial_marking(place::Place) = (place.initialMarking)()

#!_sortref(dd::DeclDict, p::PNML.Place) = sortref(p)
sortref(place::Place) = sortref(place.sorttype)::SortRef
sortof(place::Place) = sortof(sortref(place))

"""
Return zero-valued object with same `basis` and `eltype` as place's marking.

Used in enabling and firing rules to deduce type of `Arc`'s `adjacent_place`.
"""
zero_marking(place::Place) = 0 * initial_marking(place)

function Base.show(io::IO, place::Place)
    print(io, nameof(typeof(place)), "(")
    show(io, pid(place)); print(io, ", ")
    show(io, name(place)); print(io, ", ")
    show(io, place.sorttype); print(io, ", ")
    show(io, term(place.initialMarking)) #initial_marking(place));
    print(io, ")")
end

#-------------------
"""
Transition node of a Petri Net Markup Language graph.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
mutable struct Transition{PNTD, C}  <: AbstractPnmlNode{PNTD}
    pntd::PNTD
    id::Symbol
    condition::C #! expression label
    namelabel::Maybe{Name}
    graphics::Maybe{Graphics}
    toolspecinfos::Maybe{Vector{ToolInfo}}
    labels::Maybe{Vector{PnmlLabel}}

    vars::Set{REFID}
    "Cache of variable substutions for this transition"
    varsubs::Vector{NamedTuple}
    #todo net::PnmlNet
    declarationdicts::DeclDict
end

pntd(t::Transition) = t.pntd
nettype(::Transition{T}) where {T <: PnmlType} = T
decldict(transition::Transition) = transition.declarationdicts

"""
    varsubs(transition) -> Vector{NamedTuple}

Access the variable substitutions of a transition.

Variable substitutions depend on the current marking.
Cache value in transition field as part of enabling rule phase of a Petri net lifecycle.
"""
function varsubs end

varsubs(transition::Transition) = transition.varsubs

"""
    condition(::Transition) -> Condition

Return condition label.
"""
condition(transition::Transition) = begin
    transition.condition
end

function Base.show(io::IO, trans::Transition)
    print(io, nameof(typeof(trans)), "(", repr(pid(trans)), ", ",  repr(name(trans)), ", ")
    show(io, term(condition(trans)))
    print(io, ")")
end

#-------------------
"""
Edge of a Petri Net Markup Language graph that connects place and transition.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
mutable struct Arc{I <: Union{Inscription,HLInscription}} <: AbstractPnmlObject
    id::Symbol
    source::RefValue{Symbol} # IDREF
    target::RefValue{Symbol} # IDREF
    inscription::I #! expression label
    namelabel::Maybe{Name}
    graphics::Maybe{Graphics}
    toolspecinfos::Maybe{Vector{ToolInfo}}
    labels::Maybe{Vector{PnmlLabel}}
    #todo net::PnmlNet
    declarationdicts::DeclDict
end

"""
    inscription(arc::Arc) -> Union{Inscription,HLInscription}
j'
Access inscription label of arc.
"""
function inscription(arc::Arc)
    arc.inscription # label
end

sortref(arc::Arc) = sortref(arc.inscription)::SortRef
sortof(arc::Arc)  = sortof(sortref(arc))
decldict(arc::Arc) = arc.declarationdicts
"""
    source(arc) -> Symbol

Return identity symbol of source of `arc`.
"""
source(arc::Arc)::Symbol = arc.source[]

"""
    target(arc) -> Symbol

Return identity symbol of target of `arc`.
"""
target(arc::Arc)::Symbol = arc.target[]

function Base.show(io::IO, arc::Arc)
    print(io, nameof(typeof(arc)), "(", repr(pid(arc)),
          ", ", repr(name(arc)),
          ", ", repr(source(arc)),
          ", ", repr(target(arc)),
          ", ")
    show(io, inscription(arc))
    print(io, ")")
end

#-------------------
"""
Reference Place node of a Petri Net Markup Language graph. For connections between pages.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct RefPlace <: ReferenceNode
    id::Symbol
    ref::Symbol # Place or RefPlace IDREF
    namelabel::Maybe{Name}
    graphics::Maybe{Graphics}
    toolspecinfos::Maybe{Vector{ToolInfo}}
    labels::Maybe{Vector{PnmlLabel}}
    #todo net::PnmlNet
    declarationdicts::DeclDict
end

#-------------------
"""
Refrence Transition node of a Petri Net Markup Language graph. For connections between pages.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct RefTransition <: ReferenceNode
    id::Symbol
    ref::Symbol # Transition or RefTransition IDREF
    namelabel::Maybe{Name}
    graphics::Maybe{Graphics}
    toolspecinfos::Maybe{Vector{ToolInfo}}
    labels::Maybe{Vector{PnmlLabel}}
    #todo net::PnmlNet
    declarationdicts::DeclDict
end

function Base.show(io::IO, r::ReferenceNode)
    print(io, nameof(typeof(r)), "(", repr(pid(r)), ",  ", repr(refid(r)), ")")
end
