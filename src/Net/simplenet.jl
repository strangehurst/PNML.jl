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

SimpleNet is a `PetriNet` wrapping a `PnmlNet`.

Omits the page level of the pnml-defined hierarchy by flattening pages.
A multi-page net can be flattened by removing referenceTransitions & referencePlaces,
and merging pages into the first page.
"""
struct SimpleNet{PNTD} <: PetriNet{PNTD}
    id::Symbol
    net::PnmlNet{PNTD}
end

"""
Construct from the flattened first network of the pnml model created from valid XML.
"""
function SimpleNet end

SimpleNet(str::AbstractString) = SimpleNet(parse_str(str))
SimpleNet(node::XMLNode)       = SimpleNet(PnmlModel(node))
SimpleNet(model::PnmlModel)    = SimpleNet(first_net(model))
function SimpleNet(net::PnmlNet)
    netcopy = deepcopy(net) #TODO Is copy needed?
    flatten_pages!(netcopy)
    SimpleNet(netcopy.id, netcopy)
end

Base.summary(io::IO, spn::SimpleNet{P}) where {P} = print(io, summary(spn))
function Base.summary(spn::SimpleNet{P}) where {P}
    string(typeof(spn), " id ", pid(spn), ", ",
        length(places(spn)), " places, ",
        length(transitions(spn)), " transitions, ",
        length(arcs(spn)), " arcs")
end

function Base.show(io::IO, spn::SimpleNet{P}) where {P}
    println(io, summary(spn))
    println(io, "places")
    println(io, places(spn))
    println(io, "transitions")
    println(io, transitions(spn))
    println(io, "arcs")
    print(io, arcs(spn))
end

#-------------------------------------------------------------------------------
# Implement PNML Petri Net interface. See interface.jl for docstrings.
#-------------------------------------------------------------------------------

pid(spn::SimpleNet) = spn.id

pages(spn::SimpleNet)          = pages(spn.net)
places(spn::SimpleNet)         = firstpage(spn.net).places
transitions(spn::SimpleNet)    = firstpage(spn.net).transitions
arcs(spn::SimpleNet)           = firstpage(spn.net).arcs
refplaces(spn::SimpleNet)      = firstpage(spn.net).refPlaces
reftransitions(spn::SimpleNet) = firstpage(spn.net).refTransitions
