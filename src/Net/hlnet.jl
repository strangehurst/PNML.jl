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
"""
typexxx(s::HLPetriNet{T}) where {T <: PnmlType} = T


"""
$(TYPEDSIGNATURES)
"""
places(s::HLPetriNet) = s.net[:places] 

"""
$(TYPEDSIGNATURES)
"""
transitions(s::HLPetriNet) = s.net[:trans]

"""
$(TYPEDSIGNATURES)
"""
arcs(s::HLPetriNet) = s.net[:arcs]
"""
$(TYPEDSIGNATURES)
"""
refplaces(s::HLPetriNet) = s.net[:refP]

"""
$(TYPEDSIGNATURES)
"""
reftransitions(s::HLPetriNet) = s.net[:refT]

