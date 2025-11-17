"""
$(TYPEDEF)
$(TYPEDFIELDS)

Place node of a Petri Net Markup Language graph.

Each place has an initial marking that has a basis matching sorttype.
M is a "multiset sort denoting a collection of tokens".
A "multiset sort over a basis sort is interpreted as
"the set of multisets over the type associated with the basis sort".
"""
mutable struct Place{S <: AbstractSortRef}  <: AbstractPnmlNode
    #! pntd::PNTD
    id::Symbol
    initialMarking::Marking #! UnionAll
    # For each place, a sort defines the type of the marking tokens on this place (sorttype).
    # The inscription of an arc to or from a place defines which tokens are added or removed
    # when the corresponding transition fires. These tokens must also be of sorttype.
    sorttype::SortType{S}
    namelabel::Maybe{Name}
    graphics::Maybe{Graphics}
    toolspecinfos::Maybe{Vector{ToolInfo}}
    extralabels::LittleDict{Symbol,Any}
    declarationdicts::DeclDict   #todo net::PnmlNet
end

initial_marking(place::Place) = (place.initialMarking)()

sortref(place::Place) = sortref(place.sorttype)::AbstractSortRef

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
mutable struct Transition  <: AbstractPnmlNode
    #!pntd::PNTD
    id::Symbol
    condition::Labels.Condition #! boolean expression label
    namelabel::Maybe{Name}
    graphics::Maybe{Graphics}
    toolspecinfos::Maybe{Vector{ToolInfo}}
    extralabels::LittleDict{Symbol,Any}

    vars::Set{REFID}
    "Cache of variable substutions for this transition"
    varsubs::Vector{NamedTuple}
    declarationdicts::DeclDict
end

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
@kwdef mutable struct Arc{T <: PnmlExpr} <: AbstractPnmlNode #Object
    id::Symbol
    source::RefValue{Symbol} # IDREF
    target::RefValue{Symbol} # IDREF
    inscription::Inscription{T} #! expression label
    arctypelabel::ArcType
    namelabel::Maybe{Name}
    graphics::Maybe{Graphics}
    toolspecinfos::Maybe{Vector{ToolInfo}}
    extralabels::LittleDict{Symbol,Any}
    #todo net::PnmlNet
    declarationdicts::DeclDict
end

"""
    inscription(arc::Arc) -> Inscription

Access inscription label of arc.
"""
function inscription(arc::Arc)
    arc.inscription # label
end

"""
    arctypelabel(arc::Arc) -> ArcType

Access arctype label of arc.
"""
function arctypelabel(arc::Arc)
    arc.arctypelabel # label
end

isnormal(arc::Arc)    = isnormal(arctypelabel(arc))
isinhibitor(arc::Arc) = isinhibitor(arctypelabel(arc))
isread(arc::Arc)      = isread(arctypelabel(arc))
isreset(arc::Arc)     = isreset(arctypelabel(arc))

isnormal(label::ArcType)    = isnormal(arctype(label))
isinhibitor(label::ArcType) = isinhibitor(arctype(label))
isread(label::ArcType)      = isread(arctype(label))
isreset(label::ArcType)     = isreset(arctype(label))

isnormal(e::AbstractArcEnum)    = isa_variant(e, ArcT.normal)
isinhibitor(e::AbstractArcEnum) = isa_variant(e, ArcT.inhibitor)
isread(e::AbstractArcEnum)      = isa_variant(e, ArcT.read)
isreset(e::AbstractArcEnum)     = isa_variant(e, ArcT.reset)

sortref(arc::Arc) = sortref(arc.inscription)::AbstractSortRef

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
          ", ", repr(inscription(arc)),
          ", ", repr(arctypelabel(arc)))
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
    extralabels::LittleDict{Symbol,Any}
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
    extralabels::LittleDict{Symbol,Any}
    declarationdicts::DeclDict
end

function Base.show(io::IO, r::ReferenceNode)
    print(io, nameof(typeof(r)), "(", repr(pid(r)), ",  ", repr(refid(r)), ")")
end
