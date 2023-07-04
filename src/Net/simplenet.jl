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

SimpleNet is a concrete `AbstractPetriNet` wrapping a `PnmlNet`.

Uses a flattened net to avoid the page level of the pnml hierarchy.

A multi-page petri net can always be flattened by removing
referenceTransitions & referencePlaces, and merging pages into the first page.
"""
struct SimpleNet{PNTD} <: AbstractPetriNet{PNTD}
    id::Symbol # Not needed except for dispatch to inner constructor.
    net::PnmlNet{PNTD} #! M, I, C, S} #! Add type parameters to make fully specified.
end

# Construct from the flattened first network of the pnml model created from valid XML.

SimpleNet(str::AbstractString) = SimpleNet(parse_str(str))
SimpleNet(node::XMLNode)       = SimpleNet(PnmlModel(node))
SimpleNet(model::PnmlModel)    = SimpleNet(first_net(model))

function SimpleNet(net::PnmlNet)
    #! deepcopy(net) # TODO Is copy needed?
    flatten_pages!(net) #TODO
    SimpleNet(pid(net), net)
end

#-------------------------------------------------------------------------------
# Implement PNML Petri Net interface. See interface.jl for docstrings.
#-------------------------------------------------------------------------------
