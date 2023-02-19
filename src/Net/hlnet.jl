"""
Wrap a single pnml net. Presumes that the net does not need to be flattened
as all content is in firstpage.

$(TYPEDEF)
$(TYPEDFIELDS)

# Details

"""
struct HLPetriNet{PNTD} <: AbstractPetriNet{PNTD}
    net::PnmlNet{PNTD}
end
"Construct from string of valid pnml XML, using the first network in model."
HLPetriNet(str::AbstractString) = HLPetriNet(parse_str(str))
HLPetriNet(model::PnmlModel)    = HLPetriNet(first_net(model))

#-------------------------------------------------------------------------------
# Implement PNML Petri Net interface.
#-------------------------------------------------------------------------------

# Delegate to wrapped net.
pid(hlpn::HLPetriNet) = pid(hlpn.net)

# Flattened to page[1], so simple vectors.
places(hlpn::HLPetriNet)      = places(firstpage(hlpn.net))
transitions(hlpn::HLPetriNet) = transitions(firstpage(hlpn.net))
arcs(hlpn::HLPetriNet)        = arcs(firstpage(hlpn.net))
refplaces(hlpn::HLPetriNet)   = refPlaces(firstpage(hlpn.net))
reftransitions(hlpn::HLPetriNet) = refPlaces(firstpage(hlpn.net))
