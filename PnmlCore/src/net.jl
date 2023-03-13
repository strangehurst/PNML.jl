
# struct PnmlNetData{PNTD, M, I, C, S}
#     place_dict::OrderedDict{Symbol, Place{PNTD,M,S}}
#     refPlace_dict::OrderedDict{Symbol, RefPlace{PNTD}}
#     transition_dict::OrderedDict{Symbol, Transition{PNTD,C}}
#     refTransition_dict::OrderedDict{Symbol, RefTransition{PNTD}}
#     arc_dict::OrderedDict{Symbol, Arc{PNTD,I}}
# end


"""
$(TYPEDEF)
$(TYPEDFIELDS)

One Petri Net of a PNML model.
"""
struct PnmlNet{PNTD<:PnmlType, PG,PL,TR,AR,RP,RT}  #!M, I, C, S}
    type::PNTD
    id::Symbol

    #pagedict::OrderedDict{Symbol,Page{PNTD, M, I, C, S}}  #! PAGE TREE
    netdata::PnmlNetData{PNTD,PG,PL,TR,AR,RP,RT}
    pageset::OrderedSet{Symbol}  #! PAGE TREE NODE set of page ids

    #TODO add dicts shared with pages for places, transitions, arcs, refs

    declaration::Declaration
    name::Maybe{Name}
    com::ObjectCommon
    xml::XMLNode

    # function PnmlNet(pntd::PNTD, id::Symbol, netdata::PnmlNetData{PG,PL,TR,AR,RP,RT}, pageset, declare, name,
    #                  oc::ObjectCommon, xml::XMLNode)
    #     isempty(pages) && throw(ArgumentError("PnmlNet must have at least one page"))
    #     #new{typeof(pntd),marking_type(pntd),inscription_type(pntd),condition_type(pntd),sort_type(pntd)}
    #     new(pntd, id, pagedict, netdata, pageset,
    #             declare, name, oc, xml)
    # end
end

nettype(::PnmlNet{T}) where {T <: PnmlType} = T

pnmlnet_type(::Type{T}) where {T<:PnmlType} = PnmlNet(T,
                                                      marking_type(T),
                                                      inscription_type(T),
                                                      condition_type(T),
                                                      sort_type(T)
                                       )
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

condition_type(net::PnmlNet)      = condition_type(nettype(net))
condition_value_type(net::PnmlNet) = condition_value_type(nettype(net))

inscription_type(net::PnmlNet) = inscription_type(nettype(net))
inscription_value_type(net::PnmlNet) = inscription_value_type(nettype(net))

marking_type(net::PnmlNet) = marking_type(nettype(net))
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

places(net::PnmlNet)         = Iterators.flatten(places.(pages(net)))
transitions(net::PnmlNet)    = Iterators.flatten(transitions.(pages(net)))
arcs(net::PnmlNet)           = Iterators.flatten(arcs.(pages(net)))
refplaces(net::PnmlNet)      = Iterators.flatten(refplaces.(pages(net)))
reftransitions(net::PnmlNet) = Iterators.flatten(reftransitions.(pages(net)))

place(net::PnmlNet, id::Symbol)        = first(Fix2(haspid,id), places(net))
place_ids(net::PnmlNet)                = Iterators.flatten(place_ids.(pages(net)))
has_place(net::PnmlNet, id::Symbol)    = any(Fix2(haspid, id), places(net))

marking(net::PnmlNet, placeid::Symbol) = marking(place(net, placeid))

"""
    currentMarkings(net) -> LVector{marking_value_type(n)}

LVector labelled with place id and holding marking's value.
"""
currentMarkings(net::PnmlNet) = begin
    m1 = LVector((;[p => marking(net, p)() for p in place_ids(net)]...)) #! does this allocate?
    return m1
end

transition(net::PnmlNet, id::Symbol)         = first(Iterators.filter(Fix2(haspid,id), transitions(net)))
transition_ids(net::PnmlNet)                 = Iterators.flatten(transition_ids.(pages(net)))
has_transition(net::PnmlNet, id::Symbol)     = any(Fix2(haspid, id), transitions(net))

condition(net::PnmlNet, trans_id::Symbol) = condition(transition(net, trans_id))
conditions(net::PnmlNet) =
    LVector{condition_value_type(net)}((;[t => condition(net, t) for t in transition_ids(net)]...))

arc(net::PnmlNet, id::Symbol)         = first(Iterators.filter(Fix2(haspid,id), arcs(net)))
arc_ids(net::PnmlNet)                 = Iterators.flatten(arc_ids.(pages(net)))
has_arc(net::PnmlNet, id::Symbol)     = any(Fix2(has_arc, id), pages(net))

all_arcs(net::PnmlNet, id::Symbol) = filter(a -> source(a) === id || target(a) === id, arcs(net))
src_arcs(net::PnmlNet, id::Symbol) = filter(a -> source(a) === id, arcs(net))
tgt_arcs(net::PnmlNet, id::Symbol) = filter(a -> target(a) === id, arcs(net))

inscription(net::PnmlNet, arc_id::Symbol) = first(Iterators.filter(Fix2(haspid,arc_id), arcs(net)))
inscriptionV(net::PnmlNet) = Vector((;[t=>inscription(net, t)() for t in transition_ids(net)]...))

#! refplace and reftransition should only be used to derefrence, flatten pages.
#TODO Add dereferenceing for place, transition, arc traversal.
refplace(net::PnmlNet, id::Symbol)         = first(Iterators.filter(Fix2(haspid,id), refplaces(net)))
refplace_ids(net::PnmlNet)                 = Iterators.flatten(refplace_ids.(pages(net)))
has_refP(net::PnmlNet, ref_id::Symbol)     = any(Fix2(has_refP, ref_id), pages(net))

reftransition(net::PnmlNet, id::Symbol)         = find(id, reftransitions(net))
reftransition_ids(net::PnmlNet)                 = Iterators.flatten(reftransition_ids.(pages(net)))
has_refT(net::PnmlNet, ref_id::Symbol)          = any(Fix2(has_refP, ref_id), pages(net))

#--------------
function pagetree(net::PnmlNet)
    for pg in net.pageset
        println(pg)
        pagetree(net.pagedict[pg])
    end
end
function pagetree(pg::Page, inc = 1)
    for sp in pg.pageset
        print("    "^inc)
        println(sp)
        pagetree(pg.pagedict[sp], inc+1)
    end
end
