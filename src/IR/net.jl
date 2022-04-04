"""
$(TYPEDEF)
$(TYPEDFIELDS)

One Petri Net of a PNML model.
"""
struct PnmlNet{PNTD<:PnmlType}
    id::Symbol
    type::PNTD #TODO
    pages::Vector{Page}
    declaration::Declaration

    com::ObjectCommon
    xml::XMLNode
end

"""
$(TYPEDSIGNATURES)
"""
function PnmlNet(d::PnmlDict, pntd::PNTD, xml::XMLNode) where {PNTD<:PnmlType}
    PnmlNet{PNTD}(d[:id], pntd, d[:pages], d[:declaration], ObjectCommon(d), xml)
end

pid(net::PnmlNet) = net.id
pages(net::PnmlNet) = net.pages
declarations(net::PnmlNet) = declarations(net.declaration)

has_labels(net::PnmlNet) = has_labels(net.com)
has_xml(net::PnmlNet) = true
xmlnode(net::PnmlNet) = net.xml

"Usually the only interesting page."
firstpage(net::PnmlNet) = net.pages[1]
