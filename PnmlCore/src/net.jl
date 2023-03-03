"""
$(TYPEDEF)
$(TYPEDFIELDS)

One Petri Net of a PNML model.
"""
struct PnmlNet{PNTD<:PnmlType, M, I, C, S}
    type::PNTD
    id::Symbol

    pagedict::OrderedDict{Symbol,Page{PNTD, M, I, C, S}}  #! PAGE TREE
    pageset::OrderedSet{Symbol}  #! PAGE TREE NODE set of page ids

    declaration::Declaration
    name::Maybe{Name}
    com::ObjectCommon
    xml::XMLNode

    function PnmlNet(pntd::PnmlType, id::Symbol, pagedict, pages, declare, name,
                     oc::ObjectCommon, xml::XMLNode)
        isempty(pages) && throw(ArgumentError("PnmlNet must have at least one page"))
        new{typeof(pntd),
            marking_type(pntd),
            inscription_type(pntd),
            condition_type(pntd),
            sort_type(pntd)}(pntd, id, pagedict, pages, declare, name, oc, xml)
    end
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

pages(net::PnmlNet)        = values(net.pagedict) #! Returns an iterator.

"Usually the only interesting page."
firstpage(net::PnmlNet)    = (first ∘ pages)(net)

declarations(net::PnmlNet) = declarations(net.declaration) # Forward
common(net::PnmlNet)       = net.com

has_labels(net::PnmlNet) = has_labels(net.com)
xmlnode(net::PnmlNet)    = net.xml

has_name(net::PnmlNet) = !isnothing(net.name)
name(net::PnmlNet)     = has_name(net) ? net.name.text : ""

# Return first non-nothing returned by `f`.
#TODO use a mutator to fill the well-typed output.
function _find_x(id::Symbol, itr)
    y = getfirst(Fix2(haspid, id), itr)
    !isnothing(y) && return y
    # Assume exists (that is what has_x is for).
    # By excluding `nothing` maybe it will be type stable.
    error("$f returned nothing for $id on pid $(pid(x)) $(typeof(x))")
end

places(net::PnmlNet)         = mapreduce(places, vcat, pages(net);      init = place_type(net.type)[])::Vector{place_type(net)}
transitions(net::PnmlNet)    = mapreduce(transitions, vcat, pages(net); init = transition_type(net.type)[])::Vector{transition_type(net)}
arcs(net::PnmlNet)           = mapreduce(arcs, vcat, pages(net);        init = arc_type(net.type)[])::Vector{arc_type(net)}
refplaces(net::PnmlNet)      = mapreduce(refplaces, vcat, pages(net);   init = refplace_type(net.type)[])::Vector{refplace_type(net)}
reftransitions(net::PnmlNet) = mapreduce(reftransitions, vcat, pages(net); init = reftransition_type(net.type)[])::Vector{reftransition_type(net)}

place(net::PnmlNet, id::Symbol)         = _find_x(id, places(net)) # Note the plural.
place_ids(net::PnmlNet)::Vector{Symbol} = mapreduce(place_ids, vcat, pages(net); init = Vector{Symbol}[])
has_place(net::PnmlNet, id::Symbol)     = any(Fix2(has_place, id), pages(net))

marking(net::PnmlNet, placeid::Symbol) = marking(place(net, placeid))
"""
    currentMarkings(net) -> LVector{marking_value_type(n)}

LVector labelled with place id and holding marking's value.
"""
currentMarkings(net::PnmlNet) = begin
    m1 = LVector((;[p=>marking(net, p)() for p in place_ids(net)]...))
    return m1
end
transition(net::PnmlNet, id::Symbol)         = _find_x(id, transitions(net))
transition_ids(net::PnmlNet)::Vector{Symbol} = mapreduce(transition_ids, vcat, pages(net); init = Vector{Symbol}[])
has_transition(net::PnmlNet, id::Symbol)     = any(Fix2(has_transition, id), pages(net))

condition(net::PnmlNet, trans_id::Symbol) = condition(transition(net, trans_id))
conditions(net::PnmlNet) =
    LVector{condition_value_type(net)}((;[t => condition(net, t) for t in transition_ids(net)]...))

arc(net::PnmlNet, id::Symbol)         = _find_x(id, arcs(net))
arc_ids(net::PnmlNet)::Vector{Symbol} = mapreduce(arc_ids, vcat, pages(net); init = Vector{Symbol}[])
has_arc(net::PnmlNet, id::Symbol)     = any(Fix2(has_arc, id), pages(net))

all_arcs(net::PnmlNet, id::Symbol) = mapreduce(Fix2(all_arcs, id), vcat, pages(net); init = arc_type(net.type)[])
src_arcs(net::PnmlNet, id::Symbol) = mapreduce(Fix2(src_arcs, id), vcat, pages(net); init = arc_type(net.type)[])
tgt_arcs(net::PnmlNet, id::Symbol) = mapreduce(Fix2(tgt_arcs, id), vcat, pages(net); init = arc_type(net.type)[])

inscription(net::PnmlNet, arc_id::Symbol) = _find_x(arc_id, inscriptions(net))
inscriptionV(net::PnmlNet) = Vector((;[t=>inscription(net, t)() for t in transition_ids(net)]...))

#! refplace and reftransition should only be used to derefrence, flatten pages.
#TODO Add dereferenceing for place, transition, arc traversal.
refplace(net::PnmlNet, id::Symbol)         = _find_x(id, refplace(net))
refplace_ids(net::PnmlNet)::Vector{Symbol} = mapreduce(refplace_ids, vcat, pages(net))
has_refP(net::PnmlNet, ref_id::Symbol)     = any(Fix2(has_refP, ref_id), pages(net))

reftransition(net::PnmlNet, id::Symbol)         = _find_x(id, reftransition(net))
reftransition_ids(net::PnmlNet)::Vector{Symbol} = mapreduce(reftransition_ids, vcat, pages(net); init = Vector{Symbol}[])
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
