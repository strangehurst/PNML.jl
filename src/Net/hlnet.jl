"""
Wrap a single pnm net.

$(TYPEDEF)
$(TYPEDFIELDS)

# Details

"""
struct HLPetriNet{PNTD} <: PetriNet{PNTD}
    net::PnmlNet{PNTD}
end
"Construct from string of valid pnml XML using the first network"
HLPetriNet(str::AbstractString) = HLPetriNet(parse_str(str))
HLPetriNet(model::PnmlModel)  = HLPetriNet(first_net(model))

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
places(petrinet::HLPetriNet)      = firstpage(petrinetnet).places
transitions(petrinet::HLPetriNet) = firstpage(petrinet.net).transitions
"Return vector of arcs from first page."
arcs(petrinet::HLPetriNet)        = firstpage(petrinet.net).arcs
refplaces(petrinet::HLPetriNet)   = firstpage(petrinet.net).refPlaces
reftransitions(petrinet::HLPetriNet) = firstpage(petrinet.net).refTransitions
