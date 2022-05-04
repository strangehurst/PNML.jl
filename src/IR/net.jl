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

    name::Maybe{Name}
    com::ObjectCommon
    xml::XMLNode
end

function PnmlNet(pntd::PNTD, id::Symbol, pages, declare, name, oc::ObjectCommon, xml::XMLNode) where {PNTD<:PnmlType}
    PnmlNet{PNTD, typeof(declare)}(pntd, id, pages, declare, name, oc, xml)
end

pid(net::PnmlNet) = net.id
pages(net::PnmlNet) = net.pages
declarations(net::PnmlNet) = declarations(net.declaration)

has_labels(net::PnmlNet) = has_labels(net.com)
xmlnode(net::PnmlNet) = net.xml

has_name(net::PnmlNet) = hasproperty(net, :name) && !isnothing(net.name)
name(net::PnmlNet) = net.name.text

"Usually the only interesting page."
firstpage(net::PnmlNet) = net.pages[1]
