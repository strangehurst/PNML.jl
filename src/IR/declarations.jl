
#-------------------
"""
Declarations are the core of high-level Petri Net.
They define objects/names that are used for conditions, inscriptions, markings.
They are attached to PNML nets and pages.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct Declaration
    d::PnmlLabel # TODO what do declarations contain? Land of Symbolics.jl.
    com::ObjectCommon
    xml::XMLNode
end

Declaration(pdict::PnmlDict, xml::XMLNode) = 
    Declaration(PnmlLabel(pdict, xml), ObjectCommon(pdict), xml)

