"""
$(TYPEDEF)
$(TYPEDFIELDS)

One Petri Net of a PNML model.
"""
struct PnmlNet{PNTD<:PnmlType, M, I, C, S}
    type::PNTD
    id::Symbol
    pagedict::OrderedDict{Symbol, Page{PNTD, M, I, C, S}} # shared
    netdata::PnmlNetData{PNTD, M, I, C, S} # for places, transitions, arcs, refs
    netsets::PnmlNetSets # non-shared indexes into `netdata`
    declaration::Declaration
    name::Maybe{Name}
    com::ObjectCommon
    xml::XMLNode

#     function PnmlNet(pntd::PNTD, id::Symbol, pagedict, netdata, netsets, declare, name,
#                      oc::ObjectCommon,
#                      xml::XMLNode)
#         isempty(pagedict) && throw(ArgumentError("PnmlNet must have at least one page"))
#         new{typeof(pntd),
#             marking_type(pntd),
#             inscription_type(pntd),
#             condition_type(pntd),
#             sort_type(pntd)}(pntd, id, pagedict, netdata, netsets, declare, name, oc, xml)
#     end
end

nettype(::PnmlNet{T}) where {T <: PnmlType} = T

pnmlnet_type(::Type{T}) where {T<:PnmlType} = PnmlNet(T,
                                                      marking_type(T),
                                                      inscription_type(T),
                                                      condition_type(T),
                                                      sort_type(T))

page_type(::Type{T}) where {T<:PnmlType} = Page{T,
                                                marking_type(T),
                                                inscription_type(T),
                                                condition_type(T),
                                                sort_type(T)}

place_type(::Type{T}) where {T<:PnmlType}         = Place{T, marking_type(T), sort_type(T)}
transition_type(::Type{T}) where {T<:PnmlType}    = Transition{T, condition_type(T)}
arc_type(::Type{T}) where {T<:PnmlType}           = Arc{T, inscription_type(T)}
refplace_type(::Type{T}) where {T<:PnmlType}      = RefPlace{T}
reftransition_type(::Type{T}) where {T<:PnmlType} = RefTransition{T}

page_type(::PnmlNet{T}) where {T<:PnmlType} = Page{T,
                                                   marking_type(T),
                                                   inscription_type(T),
                                                   condition_type(T),
                                                   sort_type(T)}
place_type(::PnmlNet{T}) where {T<:PnmlType} = Place{T, marking_type(T), sort_type(T)}
transition_type(::PnmlNet{T}) where {T<:PnmlType}    = Transition{T, condition_type(T)}
arc_type(::PnmlNet{T}) where {T<:PnmlType}           = Arc{T, inscription_type(T)}
refplace_type(::PnmlNet{T}) where {T<:PnmlType}      = RefPlace{T}
reftransition_type(::PnmlNet{T}) where {T<:PnmlType} = RefTransition{T}

sort_type(net::PnmlNet) = sort_type(nettype(net))

condition_type(net::PnmlNet)       = condition_type(nettype(net))
condition_value_type(net::PnmlNet) = condition_value_type(nettype(net))

inscription_type(net::PnmlNet)       = inscription_type(nettype(net))
inscription_value_type(net::PnmlNet) = inscription_value_type(nettype(net))

marking_type(net::PnmlNet)       = marking_type(nettype(net))
marking_value_type(net::PnmlNet) = marking_value_type(nettype(net))

#--------------------------------------
pid(net::PnmlNet)          = net.id

# Return iterator over pages.
pages(net::PnmlNet)        = values(net.pagedict) #! Returns an iterator.

"Usually the only interesting page."
firstpage(net::PnmlNet)    = (first ∘ pages)(net)

declarations(net::PnmlNet) = declarations(net.declaration) # Forward
common(net::PnmlNet)       = net.com

has_labels(net::PnmlNet) = has_labels(net.com)
xmlnode(net::PnmlNet)    = net.xml

has_name(net::PnmlNet) = !isnothing(net.name)
name(net::PnmlNet)     = has_name(net) ? net.name.text : ""

places(net::PnmlNet)         = values(net.netdata.place_dict) # !Iterators.flatten(places.(pages(net)))
transitions(net::PnmlNet)    = values(net.netdata.transition_dict)
arcs(net::PnmlNet)           = values(net.netdata.arc_dict)
refplaces(net::PnmlNet)      = values(net.netdata.refplace_dict)
reftransitions(net::PnmlNet) = values(net.netdata.reftransition_dict)

place(net::PnmlNet, id::Symbol)        = net.netdata.place_dict[id]
place_ids(net::PnmlNet)                = keys(net.netdata.place_dict)
has_place(net::PnmlNet, id::Symbol)    = haskey(net.netdata.place_dict, id)

marking(net::PnmlNet, placeid::Symbol) = marking(place(net, placeid))

"""
    currentMarkings(net) -> LVector{marking_value_type(n)}

LVector labelled with place id and holding marking's value.
"""
currentMarkings(net::PnmlNet) = begin
    m1 = LVector((;[id => marking(p)() for (id,p) in pairs(net.netdata.place_dict)]...)) #! does this allocate?
    return m1
end

transition(net::PnmlNet, id::Symbol)      = net.netdata.transition_dict[id]
transition_ids(net::PnmlNet)              = keys(net.netdata.transition_dict)
has_transition(net::PnmlNet, id::Symbol)  = haskey(net.netdata.transition_dict, id)

condition(net::PnmlNet, trans_id::Symbol) = condition(transition(net, trans_id))
conditions(net::PnmlNet) =
LVector{condition_value_type(net)}((;[t => condition(net, t) for (id,t) in pairs(net.netdata.transition_dict)]...))

arc(net::PnmlNet, id::Symbol)      = net.netdata.arc_dict[id]
arc_ids(net::PnmlNet)              = keys(net.netdata.arc_dict)
has_arc(net::PnmlNet, id::Symbol)  = haskey(net.netdata.arc_dict, id)

all_arcs(net::PnmlNet, id::Symbol) = filter(a -> source(a) === id || target(a) === id, arcs(net))
src_arcs(net::PnmlNet, id::Symbol) = filter(a -> source(a) === id, arcs(net))
tgt_arcs(net::PnmlNet, id::Symbol) = filter(a -> target(a) === id, arcs(net))

inscription(net::PnmlNet, arc_id::Symbol) = net.netdata.arc_dict[arc_id]
inscriptionV(net::PnmlNet) = Vector((;[id => inscription(net, t)() for (id,t) in pairs(net.netdata.transition_dict)]...))

#! refplace and reftransition should only be used to derefrence, flatten pages.
#TODO Add dereferenceing for place, transition, arc traversal.
refplace(net::PnmlNet, id::Symbol)         = net.netdata.refplace_dict[id]
refplace_ids(net::PnmlNet)                 = keys(net.netdata.refplace_dict)
has_refP(net::PnmlNet, ref_id::Symbol)     = haskey(net.netdata.refplace_dict, ref_id)

reftransition(net::PnmlNet, id::Symbol)    = net.netdata.reftransition_dict[id]
reftransition_ids(net::PnmlNet)            = keys(net.netdata.reftransition_dict)
has_refT(net::PnmlNet, ref_id::Symbol)     = haskey(net.netdata.reftransition_dict, ref_id)

#--------------
function pagetree(net::PnmlNet)
    for pg in net.netsets.page_set
        println(pg)
        pagetree(net.pagedict[pg])
    end
end
function pagetree(pg::Page, inc = 1)
    for sp in pg.netsets.page_set
        print("    "^inc)
        println(sp)
        pagetree(pg.pagedict[sp], inc+1)
    end
end
