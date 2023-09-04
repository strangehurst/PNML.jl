"""
Wrap a single pnml net. Presumes that the net does not need to be flattened
as all content is in first page.

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