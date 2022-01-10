"""
$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct HLPetriNet{PNTD} <: PetriNet{PNTD}
    net::PnmlNet{PNTD}
end
HLPetriNet(str::AbstractString) = HLPetriNet(PNML.Document(str))
HLPetriNet(doc::PNML.Document)  = HLPetriNet(first_net(doc))

"""
Collapses all the pages into the first page.

$(TYPEDSIGNATURES)
"""
function HLPetriNet(net::PnmlDict)
    HLPetriNet{typeof(pnmltype(net))}(flatten_pages!(net))
end

# Implement PNML Petri Net interface.

# Delegate to wrapped net.
pid(petrinet::HLPetriNet) = pid(petrinet.net)

# Flattened to page[1], so simple vectors.
places(petrinet::HLPetriNet)      = petrinet.net.pages[1].places
transitions(petrinet::HLPetriNet) = petrinet.net.pages[1].transitions
"Return vector of arcs from first page."
arcs(petrinet::HLPetriNet)        = petrinet.net.pages[1].arcs
refplaces(petrinet::HLPetriNet)   = petrinet.net.pages[1].refPlaces
reftransitions(petrinet::HLPetriNet) = petrinet.net.pages[1].refTransitions

