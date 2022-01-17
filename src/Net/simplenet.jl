#=
# What are the characteristics of a SimpleNet?

This use-case is for explorations, might abuse the standard. The goal of PNML.jl
is to not constrain what can be parsed & represented in the
intermediate representation (IR). So many non-standard XML constructions are possible,
with the standars being a subset. It is the role of IR users to enforce semantics
upon the IR. SimpleNet takes liberties!

Assumptions about labels:
 place has numeric marking, default 0
 transition has numeric condition, default 0
 arc has source, target, numeric inscription value, default 0

# Non-simple Networks means what?

# SimpleNet

Created to be a end-to-end use case. And explore implementing something-that-works
while building upon and improving the IR. Does not try to conform to any standard.
Much of the complexity possible with pnml is ignored.

The first use is to recreate the lotka-volterra model from Petri.jl examples.
Find it in the examples folder. This is a stochastic Petri Net.

Liberties are taken with pnml, remember that standards-checking is not a goal.
A less-simple consumer of the IR can impose standards-checking.

=#

"""
$(TYPEDEF)
$(TYPEDFIELDS)

**TODO: Rename SimpleNet to TBD** 
SimpleNet wraps one net.

Omits the page level of the pnml-defined hierarchy by flattening pages.
A multi-page net can be flattened by removing referenceTransitions & referencePlaces,
and merging pages into the first page.

Only selected fields are merged.
"""
struct SimpleNet{PNTD} <: PetriNet{PNTD}
    id::Symbol
    net::PnmlNet{PNTD}
end

"Construct from string of valid pnml XML using the first network"
SimpleNet(str::AbstractString) = SimpleNet(PNML.Document(str))
SimpleNet(doc::PNML.Document)  = SimpleNet(first_net(doc))

function SimpleNet(net::PnmlNet)
    netcopy = deepcopy(net) #TODO Is copy needed?
    flatten_pages!(netcopy)
    SimpleNet(netcopy.id, netcopy)
end

Base.summary(io::IO, petrinet::SimpleNet{P}) where {P} = print(io, summary(petrinet))
function Base.summary(petrinet::SimpleNet{P}) where {P} 
    return "$(typeof(petrinet)) id $(pid(petrinet)) " *
        "$(length(places(petrinet))) places " *
        "$(length(transitions(petrinet))) transitions " *
        "$(length(arcs(petrinet))) arcs"
end

function Base.show(io::IO, petrinet::SimpleNet{P}) where {P}
    println(io, summary(petrinet), " (")
    println(io, " places")
    println(io, places(petrinet))
    println(io, " transitions")
    println(io, transitions(petrinet))
    println(io, " arcs")
    println(io, arcs(petrinet))
    print(io, ")")
end

#-------------------------------------------------------------------------------
# Implement PNML Petri Net interface.
# 
#-------------------------------------------------------------------------------

pid(petrinet::SimpleNet) = pid(petrinet.net)

places(petrinet::SimpleNet)         = firstpage(petrinet.net).places
transitions(petrinet::SimpleNet)    = firstpage(petrinet.net).transitions
arcs(petrinet::SimpleNet)           = firstpage(petrinet.net).arcs
refplaces(petrinet::SimpleNet)      = firstpage(petrinet.net).refPlaces
reftransitions(petrinet::SimpleNet) = firstpage(petrinet.net).refTransitions



#---------------------------------------------
# For Stochastic Nets, a transition is not labeled with a boolean condition,
# but with a  floating point rate
#---------------------------------------------


"""
Return a transition-id labelled vector of rate values for transitions of net `s`.

---
$(TYPEDSIGNATURES)

$(METHODLIST)
"""
function rates end

rates(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} =
    rates(petrinet, transition_ids(petrinet))

function rates(petrinet::N, idvec::Vector{Symbol}) where {T<:PnmlType, N<:PetriNet{T}}
    LVector( (; [transitionid => rate(petrinet, transitionid) for transitionid in idvec]...))
end

"""
Return rate value of `transition`.

---
$(TYPEDSIGNATURES)

$(METHODLIST)
"""
function rate end
function rate(transition)::Number
    r = get_label(transition, :rate)
    if (!isnothing(r.dict) && !isnothing(r.dict[:text]))
        value = number_value(r.dict[:text])
        isnothing(value) ? 0.0 : value
    else
        0.0
    end
end

function rate(petrinet::N, tid::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    rate(transition(petrinet, tid))
end

