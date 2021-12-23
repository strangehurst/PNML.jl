"""
$(TYPEDEF)

$(TYPEDFIELDS)
"""
struct HLPetriNet{PNTD} <: PetriNet{PNTD}
    net::PnmlDict
end
HLPetriNet(str::AbstractString) = HLPetriNet(PNML.Document(str))
HLPetriNet(doc::PNML.Document)  = HLPetriNet(first_net(doc))

"""
$(TYPEDSIGNATURES)

Collapses all the pages into the first page.
"""
function HLPetriNet(net::PnmlDict)
    HLPetriNet{typeof(pnmltype(net))}(flatten_pages!(net))
end

pid(s::HLPetriNet) = pid(s.net)

"""
$(TYPEDSIGNATURES)

Return the type representing the pntd.
There are several things with the name 'type'.
One also called PNTD is meant here..
"""
typexxx(s::HLPetriNet{T}) where {T <: PnmlType} = T

# Implement PNML Petri Net interface.
places(s::HLPetriNet) = s.net.pages[1].places
transitions(s::HLPetriNet) = s.net.pages[1].transitions
arcs(s::HLPetriNet) = s.net.pages[1].arcs
refplaces(s::HLPetriNet) = s.net.pages[1].refPlaces
reftransitions(s::HLPetriNet) = s.net.pages[1].refTransitions

