"""
$(TYPEDEF)
$(TYPEDFIELDS)

One Petri Net of a PNML model.
"""
struct PnmlNet{PNTD<:PnmlType,D}
    type::PNTD #TODO
    id::Symbol
    pages::Vector{Page}
    declaration::D

    com::ObjectCommon
    xml::XMLNode
end

function PnmlNet(pntd::PNTD, id::Symbol, pages, declare, oc::ObjectCommon, xml::XMLNode) where {PNTD<:PnmlType}
    PnmlNet{PNTD, typeof(declare)}(pntd, id, pages, declare, oc, xml)
end

pid(net::PnmlNet) = net.id
pages(net::PnmlNet) = net.pages
declarations(net::PnmlNet) = declarations(net.declaration)

has_labels(net::PnmlNet) = has_labels(net.com)
has_xml(net::PnmlNet) = true
xmlnode(net::PnmlNet) = net.xml

"Usually the only interesting page."
firstpage(net::PnmlNet) = net.pages[1]
