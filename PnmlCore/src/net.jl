"""
$(TYPEDEF)
$(TYPEDFIELDS)

One Petri Net of a PNML model.
"""
struct PnmlNet{PNTD<:PnmlType,D}
    type::PNTD
    id::Symbol
    pages::Vector{Page{PNTD}}
    declaration::D #! High-level thing.
    name::Maybe{Name}
    com::ObjectCommon
    xml::XMLNode

    function PnmlNet(pntd::PnmlType, id::Symbol, pages, declare, name,
                     oc::ObjectCommon, xml::XMLNode)
        isempty(pages) && throw(ArgumentError("PnmlNet cannot have empty `pages`"))
        pages isa Vector{Page} || throw(ArgumentError("PnmlNet `pages`` must be a Vector{Page}"))
        new{typeof(pntd),typeof(declare)}(pntd, id, pages, declare, name, oc, xml)
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

places(net::PnmlNet)         = _reduce(places, net, Place[])
transitions(net::PnmlNet)    = _reduce(transitions, net, Transition[])
arcs(net::PnmlNet)           = _reduce(arcs, net, Arc[])
refplaces(net::PnmlNet)      = _reduce(refplaces, net, RefPlace[])
reftransitions(net::PnmlNet) = _reduce(reftransitions, net, RefTransition[])

# Apply `f` to pages of net. Return first non-nothing. Else return default.
function _ppages(f::F, x::Union{PnmlNet, Page}, id::Symbol, default=nothing) where {F}
    #@show "_ppages $(typeof(x)) $(pid(x))"
    for pg in pages(x)
        pl = f(pg, id)
        !isnothing(pl) && return pl
    end
    return default
end

place(net::PnmlNet, id::Symbol)     = _ppages(place, net, id, nothing)
place_ids(net::PnmlNet)             = _reduce(place_ids, net)
has_place(net::PnmlNet, id::Symbol) = _ppages(has_place, net, id, false)

marking(net::PnmlNet, placeid::Symbol) = _ppages(marking, net, id)
currentMarkings(net::PnmlNet) = LVector((;[p=>marking(place(net, p))() for p in place_ids(net)]...))

transition(net::PnmlNet, id::Symbol)     = _ppages(transition, net, id)
transition_ids(net::PnmlNet,)            = _reduce(transition_ids, net)
has_transition(net::PnmlNet, id::Symbol) = _ppages(has_transition, net, id, false)

condition(net::PnmlNet, trans_id::Symbol) = _ppages(condition, net, trans_id)
conditions(net::PnmlNet) =
    LVector((;[t=>condition(transition(net, t)) for t in transition_ids(net)]...))

arc(net::PnmlNet, id::Symbol)      = _ppages(arc, net, id)
arc_ids(net::PnmlNet)              = _reduce(arc_ids, net)
has_arc(net::PnmlNet, id::Symbol)  = _ppages(has_arc, net, id, false)

all_arcs(net::PnmlNet, id::Symbol) = _reduce(Fix2(all_arcs, id), net)
src_arcs(net::PnmlNet, id::Symbol) = _reduce(Fix2(src_arcs, id), net)
tgt_arcs(net::PnmlNet, id::Symbol) = _reduce(Fix2(tgt_arcs, id), net)

inscription(net::PnmlNet, arc_id::Symbol) = _ppages(inscription, net, arc_id)

refplace(net::PnmlNet, id::Symbol)      = begin
    #@show "refplace net $(pid(net)) $id"
    _ppage(refplace, net, id)
end
refplace_ids(net::PnmlNet)              = _reduce(refplace_ids, net)
has_refP(net::PnmlNet, ref_id::Symbol)  = _ppage(has_refP, net, ref_id, false)

reftransition(net::PnmlNet, id::Symbol) = _ppages(reftransition, net, id)
reftransition_ids(net::PnmlNet)         = _reduce(reftransition_ids, net)
has_refT(net::PnmlNet, ref_id::Symbol)  = _ppages(has_refP, net, ref_id, false)

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
    currentMarkings(n) -> LVector{markingvaluetype(n)}

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
