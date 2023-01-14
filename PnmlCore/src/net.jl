"""
$(TYPEDEF)
$(TYPEDFIELDS)

One Petri Net of a PNML model.
"""
struct PnmlNet{PNTD<:PnmlType, M, I, C, S}
    type::PNTD
    id::Symbol
    pages::Vector{Page{PNTD, M, I, C, S}}
    declaration::Declaration #! High-level thing.
    name::Maybe{Name}
    com::ObjectCommon
    xml::XMLNode

    function PnmlNet(pntd::PnmlType, id::Symbol, pages, declare, name,
                     oc::ObjectCommon, xml::XMLNode)
        isempty(pages) && throw(ArgumentError("PnmlNet cannot have empty `pages`"))
        #pages isa Vector{Page} || throw(ArgumentError("PnmlNet `pages` must be a Vector{Page}"))
        new{typeof(pntd),
            marking_type(pntd),
            inscription_type(pntd),
            condition_type(pntd),
            sort_type(pntd)}(pntd, id, pages, declare, name, oc, xml)
    end
end

pid(net::PnmlNet)          = net.id
pages(net::PnmlNet)        = net.pages
declarations(net::PnmlNet) = declarations(net.declaration) # Forward
common(net::PnmlNet)       = net.com

has_labels(net::PnmlNet) = has_labels(net.com)
xmlnode(net::PnmlNet)    = net.xml

has_name(net::PnmlNet) = !isnothing(net.name)
name(net::PnmlNet)     = has_name(net) ? net.name.text : ""

"Usually the only interesting page."
firstpage(net::PnmlNet) = first(pages(net))

# Mapreduce `f` using `append!` over all pages of the net.
_reduce(f, net, init=Symbol[]) = mapreduce(f, append!, pages(net); init)

#! XXX not type-stable? inferred as Any for SimpleNet!
places(net::PnmlNet)         = _reduce(places, net, place_type(net.type)[])
transitions(net::PnmlNet)    = _reduce(transitions, net, transition_type(net.type)[])
arcs(net::PnmlNet)           = _reduce(arcs, net, arc_type(net.type)[])
refplaces(net::PnmlNet)      = _reduce(refplaces, net, refplace_type(net.type)[])
reftransitions(net::PnmlNet) = _reduce(reftransitions, net, reftransition_type(net.type)[])

# Apply `f` to pages of net/page. Return first non-nothing. Else return `nothing`.
function _find_x(@nospecialize(f::F), x::Union{PnmlNet, Page}, id::Symbol) where {F<:Function}
    for pg in PreOrderDFS(x)
        y = getfirst(Fix2(haspid, id), f(pg))
        !isnothing(y) && return y
    end
    return nothing
end

place(net::PnmlNet, id::Symbol)     = _find_x(places, net, id) # Note the plural.
place_ids(net::PnmlNet)             = _reduce(place_ids, net)
has_place(net::PnmlNet, id::Symbol) = any(Fix2(has_place, id), pages(net))

marking(net::PnmlNet, placeid::Symbol) = marking(place(net, placeid))
currentMarkings(net::PnmlNet) = LVector((;[p=>marking(net, p)() for p in place_ids(net)]...))

transition(net::PnmlNet, id::Symbol)     = _find_x(transitions, net, id)
transition_ids(net::PnmlNet,)            = _reduce(transition_ids, net)
has_transition(net::PnmlNet, id::Symbol) = any(Fix2(has_transition, id), pages(net))

condition(net::PnmlNet, trans_id::Symbol) = condition(transition(net, trans_id))
conditions(net::PnmlNet) = Vector((;[t=>condition(net, t)() for t in transition_ids(net)]...))

arc(net::PnmlNet, id::Symbol)      = _find_x(arcs, net, id)
arc_ids(net::PnmlNet)              = _reduce(arc_ids, net)
has_arc(net::PnmlNet, id::Symbol)  = any(Fix2(has_arc, id), pages(net))

all_arcs(net::PnmlNet, id::Symbol) = _reduce(Fix2(all_arcs, id), net)
src_arcs(net::PnmlNet, id::Symbol) = _reduce(Fix2(src_arcs, id), net)
tgt_arcs(net::PnmlNet, id::Symbol) = _reduce(Fix2(tgt_arcs, id), net)

inscription(net::PnmlNet, arc_id::Symbol) = _find_x(inscriptions, net, arc_id)
inscriptionV(net::PnmlNet) = Vector((;[t=>inscription(net, t)() for t in transition_ids(net)]...))


#! refplace and reftransition should only be used to derefrence, flatten pages.
#TODO Add dereferenceing for place, transition, arc traversal.
refplace(net::PnmlNet, id::Symbol)      = _find_x(refplace, net, id)
refplace_ids(net::PnmlNet)              = _reduce(refplace_ids, net)
has_refP(net::PnmlNet, ref_id::Symbol)  = any(Fix2(has_refP, ref_id), pages(net))

reftransition(net::PnmlNet, id::Symbol) = _find_x(reftransition, net, id)
reftransition_ids(net::PnmlNet)         = _reduce(reftransition_ids, net)
has_refT(net::PnmlNet, ref_id::Symbol)  = any(Fix2(has_refP, ref_id), page(net))

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
#! TODO  Subpages
"""
    currentMarkings(n) -> LVector{marking_value_type(n)}

LVector labelled with place id and holding marking's value.
"""
currentMarkings(net::PnmlNet, page_idx) = currentMarkings(pages(net)[page_idx])

transition(net::PnmlNet, id::Symbol, page_idx)     = transition(pages(net)[page_idx], id)
transition_ids(net::PnmlNet, page_idx)             = transition_ids(pages(net)[page_idx])
has_transition(net::PnmlNet, id::Symbol, page_idx) = has_transition(pages(net)[page_idx], id)

condition(net::PnmlNet, trans_id::Symbol, page_idx) = condition(pages(net)[page_idx], trans_id)
conditions(net::PnmlNet, page_idx) = conditions(pages(net)[page_idx])

arc(net::PnmlNet, id::Symbol, page_idx)      = arc(pages(net)[page_idx], id)
arc_ids(net::PnmlNet, page_idx)              = arc_ids(pages(net)[page_idx])
has_arc(net::PnmlNet, id::Symbol, page_idx)  = has_arc(pages(net)[page_idx], id)

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
