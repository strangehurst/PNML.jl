"""
$(TYPEDEF)
$(TYPEDFIELDS)

One Petri Net of a PNML model.
"""
struct PnmlNet{PNTD<:PnmlType,D}
    type::PNTD
    id::Symbol
    pages::Vector{Page{PNTD}}
    declaration::D
    name::Maybe{Name}
    com::ObjectCommon
    xml::XMLNode
end

function PnmlNet(pntd::PnmlType, id::Symbol, pages, declare, name,
                    oc::ObjectCommon, xml::XMLNode)
    PnmlNet{typeof(pntd),typeof(declare)}(pntd, id, pages, declare, name, oc, xml)
end

pid(net::PnmlNet)          = net.id
pages(net::PnmlNet)        = net.pages
declarations(net::PnmlNet) = declarations(net.declaration)

has_labels(net::PnmlNet) = has_labels(net.com)
xmlnode(net::PnmlNet)    = net.xml

has_name(net::PnmlNet) = !isnothing(net.name)
name(net::PnmlNet)     = has_name(net) ? net.name.text : ""

"Usually the only interesting page."
firstpage(net::PnmlNet) = first(net.pages)

# Presumes net has been flattened. Or in a future implementation, collect from all pages.
places(net::PnmlNet)         = places(firstpage(net))
transitions(net::PnmlNet)    = transitions(firstpage(net))
arcs(net::PnmlNet)           = arcs(firstpage(net))
refplaces(net::PnmlNet)      = refplaces(firstpage(net))
reftransitions(net::PnmlNet) = reftransitions(firstpage(net))

# Handle individual pages here.
places(net::PnmlNet, page_idx)         = places(pages(net)[page_idx])
transitions(net::PnmlNet, page_idx)    = transitions(pages(net)[page_idx])
arcs(net::PnmlNet, page_idx)           = arcs(pages(net)[page_idx])
refplaces(net::PnmlNet, page_idx)      = refplaces(pages(net)[page_idx])
reftransitions(net::PnmlNet, page_idx) = reftransitions(pages(net)[page_idx])

has_place(net::PnmlNet, id::Symbol)           = has_place(net.pages[begin], id)
has_place(net::PnmlNet, id::Symbol, page_idx) = has_place(net.pages[page_idx], id)
place(net::PnmlNet, id::Symbol)           = place(net.pages[begin], id)
place(net::PnmlNet, id::Symbol, page_idx) = place(net.pages[page_idx], id)
place_ids(net::PnmlNet)           = place_ids(net.pages[begin])
place_ids(net::PnmlNet, page_idx) = place_ids(net.pages[page_idx])

marking(net::PnmlNet)                            = marking(net.pages[begin], placeid)
marking(net::PnmlNet, placeid::Symbol, page_idx) = marking(net.pages[page_idx], placeid)
initialMarking(net::PnmlNet)           = initialMarking(net.pages[begin])
initialMarking(net::PnmlNet, page_idx) = initialMarking(net.pages[page_idx])

transition_ids(net::PnmlNet,)          = transition_ids(net.pages[begin])
transition_ids(net::PnmlNet, page_idx) = transition_ids(net.pages[page_idx])
has_transition(net::PnmlNet, id::Symbol)           = has_transition(net.pages[begin], id)
has_transition(net::PnmlNet, id::Symbol, page_idx) = has_transition(net.pages[page_idx], id)
transition(net::PnmlNet, id::Symbol)           = transition(net.pages[begin], id)
transition(net::PnmlNet, id::Symbol, page_idx) = transition(net.pages[page_idx], id)

condition(net::PnmlNet, trans_id::Symbol)           = condition(net.pages[begin], trans_id)
condition(net::PnmlNet, trans_id::Symbol, page_idx) = condition(net.pages[page_idx], trans_id)

conditions(net::PnmlNet)           = conditions(net.pages[begin])
conditions(net::PnmlNet, page_idx) = conditions(net.pages[page_idx])

arc_ids(net::PnmlNet)           = arc_ids(pages(net)[begin])
arc_ids(net::PnmlNet, page_idx) = arc_ids(pages(net)[page_idx])

has_arc(net::PnmlNet, id::Symbol)           = has_arc(pages(net)[begin], id)
has_arc(net::PnmlNet, id::Symbol, page_idx) = has_arc(pages(net)[page_idx], id)

arc(net::PnmlNet, id::Symbol)           = arc(pages(net)[begin], id)
arc(net::PnmlNet, id::Symbol, page_idx) = arc(pages(net)[page_idx], id)

all_arcs(net::PnmlNet, id::Symbol)           = all_arcs(pages(net)[begin], id)
all_arcs(net::PnmlNet, id::Symbol, page_idx) = all_arcs(pages(net)[page_idx], id)

src_arcs(net::PnmlNet, id::Symbol)           = src_arcs(pages(net)[begin], id)
src_arcs(net::PnmlNet, id::Symbol, page_idx) = src_arcs(pages(net)[page_idx], id)

tgt_arcs(net::PnmlNet, id::Symbol)           = tgt_arcs(pages(net)[begin], id)
tgt_arcs(net::PnmlNet, id::Symbol, page_idx) = tgt_arcs(pages(net)[page_idx], id)

inscription(net::PnmlNet, arc_id::Symbol)           = inscription(pages(net)[begin], arc_id)
inscription(net::PnmlNet, arc_id::Symbol, page_idx) = inscription(pages(net)[page_idx], arc_id)

has_refP(net::PnmlNet, ref_id::Symbol)           = has_refP(pages(net)[begin], ref_id)
has_refP(net::PnmlNet, ref_id::Symbol, page_idx) = has_refP(pages(net)[page_idx], ref_id)

has_refT(net::PnmlNet, ref_id::Symbol)           = has_refP(pages(net)[begin], ref_id)
has_refT(net::PnmlNet, ref_id::Symbol, page_idx) = has_refP(pages(net)[page_idx], ref_id)

refplace_ids(net::PnmlNet)           = refplace_ids(net.pages[begin])
refplace_ids(net::PnmlNet, page_idx) = refplace_ids(net.pages[page_idx])

reftransition_ids(net::PnmlNet)           = reftransition_ids(net.pages[begin])
reftransition_ids(net::PnmlNet, page_idx) = reftransition_ids(net.pages[page_idx])

refplace(net::PnmlNet, id::Symbol)           = refplace(net.pages[begin], id)
refplace(net::PnmlNet, id::Symbol, page_idx) = refplace(net.pages[page_idx], id)

reftransition(net::PnmlNet, id::Symbol)           = reftransition(net.pages[begin], id)
reftransition(net::PnmlNet, id::Symbol, page_idx) = reftransition(net.pages[page_idx], id)
