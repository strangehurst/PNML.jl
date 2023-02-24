"""
$(TYPEDEF)
$(TYPEDFIELDS)

One Petri Net of a PNML model.
"""
struct PnmlNet{PNTD<:PnmlType, M, I, C, S}
    type::PNTD
    id::Symbol
    #pgs::PageTreeNode{Page{PNTD, M, I, C, S}}
    pages::Vector{Page{PNTD, M, I, C, S}} #! make tree node wrapper?
    declaration::Declaration
    name::Maybe{Name}
    com::ObjectCommon
    xml::XMLNode

    function PnmlNet(pntd::PnmlType, id::Symbol, pages, declare, name,
                     oc::ObjectCommon, xml::XMLNode)
        isempty(pages) && throw(ArgumentError("PnmlNet cannot have empty `pages`"))
        new{typeof(pntd),
            marking_type(pntd),
            inscription_type(pntd),
            condition_type(pntd),
            sort_type(pntd)}(pntd, id, pages, declare, name, oc, xml)
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

pages(net::PnmlNet)        = net.pages #! Make this return an iteratable/iterator over tree.
"Usually the only interesting page."
firstpage(net::PnmlNet)    = (first ∘ pages)(net)

declarations(net::PnmlNet) = declarations(net.declaration) # Forward
common(net::PnmlNet)       = net.com

has_labels(net::PnmlNet) = has_labels(net.com)
xmlnode(net::PnmlNet)    = net.xml

has_name(net::PnmlNet) = !isnothing(net.name)
name(net::PnmlNet)     = has_name(net) ? net.name.text : ""

# Apply `f` over all pages of the net using `PreOrderDFS`, returning a vector.
# The type of init matters for type stability.
function _reduce(f::F, net::PnmlNet; init=Symbol[]) where {F<:Function}
    reduce(vcat,
           mapreduce(f, vcat, PreOrderDFS(pg); init) for pg in pages(net) if !isnothing(pg))
end

# Apply `f` to pages of net/page using `PreOrderDFS`.
# Return first non-nothing returned by `f`.
#TODO use a mutator to fill the well-typed output.
function _find_x(f::F, x::Union{PnmlNet, Page}, id::Symbol) where {F<:Function}
    for pg in PreOrderDFS(x)
        y = getfirst(Fix2(haspid, id), f(pg))
        !isnothing(y) && return y
    end
    # Assume exists (that is what has_x is for).
    # By excluding `nothing` maybe it will be type stable.
    error("$f returned nothing for $id on pid $(pid(x)) $(typeof(x))")
end

places(net::PnmlNet)         = _reduce(places, net;      init = place_type(net.type)[])::Vector{place_type(net)}
transitions(net::PnmlNet)    = _reduce(transitions, net; init = transition_type(net.type)[])::Vector{transition_type(net)}
arcs(net::PnmlNet)           = _reduce(arcs, net;        init = arc_type(net.type)[])::Vector{arc_type(net)}
refplaces(net::PnmlNet)      = _reduce(refplaces, net;   init = refplace_type(net.type)[])::Vector{refplace_type(net)}
reftransitions(net::PnmlNet) = _reduce(reftransitions, net; init = reftransition_type(net.type)[])::Vector{reftransition_type(net)}

place(net::PnmlNet, id::Symbol)         = _find_x(places, net, id) # Note the plural.
place_ids(net::PnmlNet)::Vector{Symbol} = _reduce(place_ids, net)
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
transition(net::PnmlNet, id::Symbol)         = _find_x(transitions, net, id)
transition_ids(net::PnmlNet)::Vector{Symbol} = _reduce(transition_ids, net)
has_transition(net::PnmlNet, id::Symbol)     = any(Fix2(has_transition, id), pages(net))

condition(net::PnmlNet, trans_id::Symbol) = condition(transition(net, trans_id))
conditions(net::PnmlNet) =
    LVector{condition_value_type(net)}((;[t => condition(net, t) for t in transition_ids(net)]...))

arc(net::PnmlNet, id::Symbol)         = _find_x(arcs, net, id)
arc_ids(net::PnmlNet)::Vector{Symbol} = _reduce(arc_ids, net)
has_arc(net::PnmlNet, id::Symbol)     = any(Fix2(has_arc, id), pages(net))

all_arcs(net::PnmlNet, id::Symbol) = _reduce(Fix2(all_arcs, id), net; init=arc_type(net.type)[])
src_arcs(net::PnmlNet, id::Symbol) = _reduce(Fix2(src_arcs, id), net; init=arc_type(net.type)[])
tgt_arcs(net::PnmlNet, id::Symbol) = _reduce(Fix2(tgt_arcs, id), net; init=arc_type(net.type)[])

inscription(net::PnmlNet, arc_id::Symbol) = _find_x(inscriptions, net, arc_id)
inscriptionV(net::PnmlNet) = Vector((;[t=>inscription(net, t)() for t in transition_ids(net)]...))

#! refplace and reftransition should only be used to derefrence, flatten pages.
#TODO Add dereferenceing for place, transition, arc traversal.
refplace(net::PnmlNet, id::Symbol)         = _find_x(refplace, net, id)
refplace_ids(net::PnmlNet)::Vector{Symbol} = _reduce(refplace_ids, net)
has_refP(net::PnmlNet, ref_id::Symbol)     = any(Fix2(has_refP, ref_id), pages(net))

reftransition(net::PnmlNet, id::Symbol)         = _find_x(reftransition, net, id)
reftransition_ids(net::PnmlNet)::Vector{Symbol} = _reduce(reftransition_ids, net)
has_refT(net::PnmlNet, ref_id::Symbol)          = any(Fix2(has_refP, ref_id), page(net))
