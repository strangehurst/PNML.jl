"""
$(TYPEDEF)
$(TYPEDFIELDS)

One Petri Net of a PNML model.
"""
@kwdef struct PnmlNet{PNTD<:PnmlType, P, T, A, RP, RT}
    type::PNTD
    id::Symbol
    pagedict::OrderedDict{Symbol, Page{PNTD, P, T, A, RP, RT}} # Shared by pages, holds all pages.
    netdata::PnmlNetData{PNTD, P, T, A, RP, RT} # Shared by pages, holds all places, transitions, arcs, refs
    page_set::OrderedSet{Symbol} # Keys of pages in pagedict owned by this net. Top-level of a tree with PnmlNetKeys.
    declaration::Declaration
    name::Maybe{Name}
    tools::Vector{ToolInfo}
    labels::Vector{PnmlLabel}
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
                                                  SortType}
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
                                                     SortType}
transition_type(::PnmlNet{T}) where {T<:PnmlType}    = Transition{T, condition_type(T)}
arc_type(::PnmlNet{T}) where {T<:PnmlType}           = Arc{T, inscription_type(T)}
refplace_type(::PnmlNet{T}) where {T<:PnmlType}      = RefPlace{T}
reftransition_type(::PnmlNet{T}) where {T<:PnmlType} = RefTransition{T}

condition_type(net::PnmlNet)       = condition_type(nettype(net))
condition_value_type(net::PnmlNet) = condition_value_type(nettype(net))

inscription_type(net::PnmlNet)       = inscription_type(nettype(net))
inscription_value_type(net::PnmlNet) = inscription_value_type(nettype(net))
rate_value_type(net::PnmlNet)        = rate_value_type(nettype(net))

marking_type(net::PnmlNet)       = marking_type(nettype(net))
marking_value_type(net::PnmlNet) = marking_value_type(nettype(net))

#--------------------------------------
pid(net::PnmlNet)  = net.id

# `pagedict` is all pages in `net`, `page_idset` only for direct pages of net.
pagedict(n::PnmlNet) = n.pagedict
page_idset(n::PnmlNet)  = n.page_set

netdata(n::PnmlNet)  = n.netdata
netsets(n::PnmlNet)  = error("PnmlNet $(pid(n)) does not have a PnmlKeySet, did you mean `netdata`?")

place_idset(n::PnmlNet)         = keys(placedict(n))
transition_idset(n::PnmlNet)    = keys(transitiondict(n))
arc_idset(n::PnmlNet)           = keys(arcdict(n))
reftransition_idset(n::PnmlNet) = keys(reftransitiondict(n))
refplace_idset(n::PnmlNet)      = keys(refplacedict(n))

""
allpages(net::PnmlNet) = allpages(pagedict(net))
allpages(pd::OrderedDict) = values(pd)

"Iterator of `Pages` directly owned by `net`."
pages(net::PnmlNet) = Iterators.filter(v -> in(pid(v), page_idset(net)), allpages(net))

"Usually the only interesting page."
firstpage(net::PnmlNet)    = (first ∘ values ∘ pagedict)(net)

declarations(net::PnmlNet) = declarations(net.declaration) # Forward

has_tools(net::PnmlNet) = true
tools(net::PnmlNet)     = net.tools

has_labels(net::PnmlNet) = true
labels(net::PnmlNet)     = net.labels

has_name(net::PnmlNet) = !isnothing(net.name)
name(net::PnmlNet)     = has_name(net) ? net.name.text : ""

places(net::PnmlNet)         = values(placedict(net))
transitions(net::PnmlNet)    = values(transitiondict(net))
arcs(net::PnmlNet)           = values(arcdict(net))
refplaces(net::PnmlNet)      = values(refplacedict(net))
reftransitions(net::PnmlNet) = values(reftransitiondict(net))

place(net::PnmlNet, id::Symbol)        = placedict(net)[id]
has_place(net::PnmlNet, id::Symbol)    = haskey(placedict(net), id)

initial_marking(net::PnmlNet, placeid::Symbol) = initial_marking(place(net, placeid))

transition(net::PnmlNet, id::Symbol)      = transitiondict(net)[id]
has_transition(net::PnmlNet, id::Symbol)  = haskey(transitiondict(net), id)

condition(net::PnmlNet, trans_id::Symbol) = condition(transition(net, trans_id))

arc(net::PnmlNet, id::Symbol)      = arcdict(net)[id]
has_arc(net::PnmlNet, id::Symbol)  = haskey(arcdict(net), id)


"""
Return `Arc` from 's' to 't' or `nothing``. Assumes there is at most one.
"""
arc(net, s::Symbol, t::Symbol) = begin
    x = Iterators.filter(a -> source(a) === s && target(a) === t, arcs(net))
    isempty(x) ? nothing : first(x)
end
all_arcs(net::PnmlNet, id::Symbol) = Iterators.filter(a -> source(a) === id || target(a) === id, arcs(net))
src_arcs(net::PnmlNet, id::Symbol) = Iterators.filter(a -> source(a) === id, arcs(net))
tgt_arcs(net::PnmlNet, id::Symbol) = Iterators.filter(a -> target(a) === id, arcs(net))

inscription(net::PnmlNet, arc_id::Symbol) = inscription(arcdict(net)[arc_id])

has_refplace(net::PnmlNet, id::Symbol)      = haskey(refplacedict(net), id)
refplace(net::PnmlNet, id::Symbol)          = refplacedict(net)[id]
has_reftransition(net::PnmlNet, id::Symbol) = haskey(reftransitiondict(net), id)
reftransition(net::PnmlNet, id::Symbol)     = reftransitiondict(net)[id]
