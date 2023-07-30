"""
$(TYPEDEF)
$(TYPEDFIELDS)

One Petri Net of a PNML model.
"""
struct PnmlNet{PNTD<:PnmlType, P, T, A, RP, RT}
    type::PNTD
    id::Symbol
    pagedict::OrderedDict{Symbol, Page{PNTD, P, T, A, RP, RT}} # Shared by pages, holds all pages.
    netdata::PnmlNetData{PNTD, P, T, A, RP, RT} # Shared by pages, holds all places, transitions, arcs, refs
    page_set::OrderedSet{Symbol} # Keys of pages in pagedict owned by this net. Top-level of a tree with PnmlNetKeys.
    declaration::Declaration
    name::Maybe{Name}
    com::ObjectCommon
    xml::XMLNode
end

nettype(::PnmlNet{T}) where {T <: PnmlType} = T

pnmlnet_type(::Type{T}) where {T<:PnmlType} = PnmlNet{T,
                                                      place_type(T),
                                                      transition_type(T),
                                                      arc_type(T),
                                                      refplace_type(T),
                                                      reftransition_type(T)}

page_type(::Type{T}) where {T<:PnmlType} = Page{T,
                                                place_type(T),
                                                transition_type(T),
                                                arc_type(T),
                                                refplace_type(T),
                                                reftransition_type(T)}

place_type(::Type{T}) where {T<:PnmlType} = Place{T,
                                                  marking_type(T),
                                                  SortType{default_sort_type(T)}}
transition_type(::Type{T}) where {T<:PnmlType}    = Transition{T, condition_type(T)}
arc_type(::Type{T}) where {T<:PnmlType}           = Arc{T, inscription_type(T)}
refplace_type(::Type{T}) where {T<:PnmlType}      = RefPlace{T}
reftransition_type(::Type{T}) where {T<:PnmlType} = RefTransition{T}

page_type(::PnmlNet{T}) where {T<:PnmlType} = Page{T,
                                                   place_type(T),
                                                   transition_type(T),
                                                   arc_type(T),
                                                   refplace_type(T),
                                                   reftransition_type(T)}

place_type(::PnmlNet{T}) where {T<:PnmlType} = Place{T,
                                                     marking_type(T),
                                                     SortType{default_sort_type(T)}}
transition_type(::PnmlNet{T}) where {T<:PnmlType}    = Transition{T, condition_type(T)}
arc_type(::PnmlNet{T}) where {T<:PnmlType}           = Arc{T, inscription_type(T)}
refplace_type(::PnmlNet{T}) where {T<:PnmlType}      = RefPlace{T}
reftransition_type(::PnmlNet{T}) where {T<:PnmlType} = RefTransition{T}

condition_type(net::PnmlNet)       = condition_type(nettype(net))
condition_value_type(net::PnmlNet) = condition_value_type(nettype(net))

inscription_type(net::PnmlNet)       = inscription_type(nettype(net))
inscription_value_type(net::PnmlNet) = inscription_value_type(nettype(net))

marking_type(net::PnmlNet)       = marking_type(nettype(net))
marking_value_type(net::PnmlNet) = marking_value_type(nettype(net))

#--------------------------------------
pid(net::PnmlNet)  = net.id

pagedict(n::PnmlNet) = n.pagedict
netdata(n::PnmlNet)  = n.netdata
netsets(n::PnmlNet)  = error("PnmlNet $(pid(n)) does not have a PnmlKeySet, did you mean `netdata`?")
page_idset(n::PnmlNet)  = n.page_set

# `pagedist` is all pages in `net`, `page_idset` (and thus `pages`) only for direct pages of net.
place_idset(n::PnmlNet)         = union([place_idset(p) for p in allpages(n)]...)
transition_idset(n::PnmlNet)    = union([transition_idset(p) for p in allpages(n)]...)
arc_idset(n::PnmlNet)           = union([arc_idset(p) for p in allpages(n)]...)
reftransition_idset(n::PnmlNet) = union([reftransition_idset(p) for p in allpages(n)]...)
refplace_idset(n::PnmlNet)      = union([refplace_idset(p) for p in allpages(n)]...)

allpages(net::PnmlNet) = (values ∘ pagedict)(net)

"Return iterator of `Pages` directly owned by `net`."
pages(net::PnmlNet) = Iterators.filter(v -> pid(v) in page_idset(net), allpages(net))

"Usually the only interesting page."
firstpage(net::PnmlNet)    = (first ∘ values ∘ pagedict)(net)

declarations(net::PnmlNet) = declarations(net.declaration) # Forward
common(net::PnmlNet)       = net.com

has_labels(net::PnmlNet) = has_labels(net.com)
xmlnode(net::PnmlNet)    = net.xml

has_name(net::PnmlNet) = !isnothing(net.name)
name(net::PnmlNet)     = has_name(net) ? net.name.text : ""

places(net::PnmlNet)         = values(placedict(net))
transitions(net::PnmlNet)    = values(transitiondict(net))
arcs(net::PnmlNet)           = values(arcdict(net))
refplaces(net::PnmlNet)      = values(refplacedict(net))
reftransitions(net::PnmlNet) = values(reftransitiondict(net))

place(net::PnmlNet, id::Symbol)        = placedict(net)[id]
has_place(net::PnmlNet, id::Symbol)    = haskey(placedict(net), id)

marking(net::PnmlNet, placeid::Symbol) = marking(place(net, placeid))

"""
    currentMarkings(net) -> LVector{marking_value_type(n)}

LVector labelled with place id and holding marking's value.
"""
currentMarkings(net::PnmlNet) = begin
    m1 = LVector((;[id => marking(p)() for (id,p) in pairs(placedict(net))]...)) #! does this allocate?
    return m1
end

transition(net::PnmlNet, id::Symbol)      = transitiondict(net)[id]
has_transition(net::PnmlNet, id::Symbol)  = haskey(transitiondict(net), id)

condition(net::PnmlNet, trans_id::Symbol) = condition(transition(net, trans_id))
conditions(net::PnmlNet) =
    LVector{condition_value_type(net)}((;[t => condition(net, t) for (id,t) in pairs(transitiondict(net))]...))

arc(net::PnmlNet, id::Symbol)      = arcdict(net)[id]
has_arc(net::PnmlNet, id::Symbol)  = haskey(arcdict(net), id)

all_arcs(net::PnmlNet, id::Symbol) = filter(a -> source(a) === id || target(a) === id, arcs(net))
src_arcs(net::PnmlNet, id::Symbol) = filter(a -> source(a) === id, arcs(net))
tgt_arcs(net::PnmlNet, id::Symbol) = filter(a -> target(a) === id, arcs(net))

inscription(net::PnmlNet, arc_id::Symbol) = inscription(arcdict(net)[arc_id])
inscriptionV(net::PnmlNet) = Vector((;[id => inscription(net, t)() for (id,t) in pairs(arcdict(net))]...))

#TODO Add dereferenceing for place, transition, arc traversal.
refplace(net::PnmlNet, id::Symbol)         = refplacedict(net)[id]
has_refP(net::PnmlNet, ref_id::Symbol)     = haskey(refplacedict(net), ref_id)

reftransition(net::PnmlNet, id::Symbol)    = reftransitiondict(net)[id]
has_refT(net::PnmlNet, ref_id::Symbol)     = haskey(reftransitiondict(net), ref_id)
