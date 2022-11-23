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
firstpage(net::PnmlNet) = first(pages(net))

# Forward to the first and only page.
# Presumes net has been flattened or only has one page.
# Or in a future implementation, collect from all pages.
places(net::PnmlNet)         = places(firstpage(net))
transitions(net::PnmlNet)    = transitions(firstpage(net))
arcs(net::PnmlNet)           = arcs(firstpage(net))
refplaces(net::PnmlNet)      = refplaces(firstpage(net))
reftransitions(net::PnmlNet) = reftransitions(firstpage(net))

place(net::PnmlNet, id::Symbol)     = place(firstpage(net), id)
place_ids(net::PnmlNet)             = place_ids(firstpage(net))
has_place(net::PnmlNet, id::Symbol) = has_place(firstpage(net), id)

marking(net::PnmlNet)          = marking(firstpage(net), placeid)
initialMarking(net::PnmlNet)   = initialMarking(firstpage(net))

transition(net::PnmlNet, id::Symbol)     = transition(firstpage(net), id)
transition_ids(net::PnmlNet,)            = transition_ids(firstpage(net))
has_transition(net::PnmlNet, id::Symbol) = has_transition(firstpage(net), id)

condition(net::PnmlNet, trans_id::Symbol) = condition(firstpage(net), trans_id)
conditions(net::PnmlNet)                  = conditions(firstpage(net))

arc(net::PnmlNet, id::Symbol)      = arc(firstpage(net), id)
arc_ids(net::PnmlNet)              = arc_ids(firstpage(net))
has_arc(net::PnmlNet, id::Symbol)  = has_arc(firstpage(net), id)
all_arcs(net::PnmlNet, id::Symbol) = all_arcs(firstpage(net), id)
src_arcs(net::PnmlNet, id::Symbol) = src_arcs(firstpage(net), id)
tgt_arcs(net::PnmlNet, id::Symbol) = tgt_arcs(firstpage(net), id)

inscription(net::PnmlNet, arc_id::Symbol) = inscription(firstpage(net), arc_id)

refplace(net::PnmlNet, id::Symbol)      = refplace(firstpage(net), id)
refplace_ids(net::PnmlNet)              = refplace_ids(firstpage(net))
has_refP(net::PnmlNet, ref_id::Symbol)  = has_refP(firstpage(net), ref_id)

reftransition(net::PnmlNet, id::Symbol) = reftransition(firstpage(net), id)
reftransition_ids(net::PnmlNet)         = reftransition_ids(firstpage(net))
has_refT(net::PnmlNet, ref_id::Symbol)  = has_refP(firstpage(net), ref_id)

#------------------------------
# Handle individual pages here.
#------------------------------
places(net::PnmlNet, page_idx)         = places(pages(net)[page_idx])
transitions(net::PnmlNet, page_idx)    = transitions(pages(net)[page_idx])
arcs(net::PnmlNet, page_idx)           = arcs(pages(net)[page_idx])
refplaces(net::PnmlNet, page_idx)      = refplaces(pages(net)[page_idx])
reftransitions(net::PnmlNet, page_idx) = reftransitions(pages(net)[page_idx])

place(net::PnmlNet, id::Symbol, page_idx)     = place(pages(net)[page_idx], id)
place_ids(net::PnmlNet, page_idx)             = place_ids(pages(net)[page_idx])
has_place(net::PnmlNet, id::Symbol, page_idx) = has_place(pages(net)[page_idx], id)

marking(net::PnmlNet, placeid::Symbol, page_idx) = marking(pages(net)[page_idx], placeid)
initialMarking(net::PnmlNet, page_idx)           = initialMarking(pages(net)[page_idx])

transition(net::PnmlNet, id::Symbol, page_idx)     = transition(pages(net)[page_idx], id)
transition_ids(net::PnmlNet, page_idx)             = transition_ids(pages(net)[page_idx])
has_transition(net::PnmlNet, id::Symbol, page_idx) = has_transition(pages(net)[page_idx], id)

condition(net::PnmlNet, trans_id::Symbol, page_idx) = condition(pages(net)[page_idx], trans_id)
conditions(net::PnmlNet, page_idx) = conditions(pages(net)[page_idx])

arc(net::PnmlNet, id::Symbol, page_idx)     = arc(pages(net)[page_idx], id)
arc_ids(net::PnmlNet, page_idx)             = arc_ids(pages(net)[page_idx])
has_arc(net::PnmlNet, id::Symbol, page_idx) = has_arc(pages(net)[page_idx], id)

all_arcs(net::PnmlNet, id::Symbol, page_idx) = all_arcs(pages(net)[page_idx], id)
src_arcs(net::PnmlNet, id::Symbol, page_idx) = src_arcs(pages(net)[page_idx], id)
tgt_arcs(net::PnmlNet, id::Symbol, page_idx) = tgt_arcs(pages(net)[page_idx], id)

inscription(net::PnmlNet, arc_id::Symbol, page_idx) = inscription(pages(net)[page_idx], arc_id)

refplace(net::PnmlNet, id::Symbol, page_idx)     = refplace(pages(net)[page_idx], id)
refplace_ids(net::PnmlNet, page_idx)             = refplace_ids(pages(net)[page_idx])
has_refP(net::PnmlNet, ref_id::Symbol, page_idx) = has_refP(pages(net)[page_idx], ref_id)

reftransition(net::PnmlNet, id::Symbol, page_idx) = reftransition(pages(net)[page_idx], id)
reftransition_ids(net::PnmlNet, page_idx)         = reftransition_ids(pages(net)[page_idx])
has_refT(net::PnmlNet, ref_id::Symbol, page_idx)  = has_refP(pages(net)[page_idx], ref_id)
