"""
$(TYPEDEF)
$(TYPEDFIELDS)

One Petri Net of a PNML model.
"""
struct PnmlNet{PNTD<:PnmlType}
    type::PNTD #TODO
    id::Symbol
    pages::Vector{Page{PNTD}}
    declaration::Declaration #! Specialize with type parameters.

    name::Maybe{Name}
    com::ObjectCommon
    xml::XMLNode
end

function PnmlNet(pntd::PNTD, id::Symbol, pages, declare, name, 
                    oc::ObjectCommon, xml::XMLNode) where {PNTD<:PnmlType}
    PnmlNet{PNTD}(pntd, id, pages, declare, name, oc, xml)
end

pid(net::PnmlNet) = net.id
pages(net::PnmlNet) = net.pages
declarations(net::PnmlNet) = declarations(net.declaration)

has_labels(net::PnmlNet) = has_labels(net.com)
xmlnode(net::PnmlNet) = net.xml

has_name(net::PnmlNet) = !isnothing(net.name)
name(net::PnmlNet) = has_name(net) ? net.name.text : ""

"Usually the only interesting page."
firstpage(net::PnmlNet) = first(net.pages)

