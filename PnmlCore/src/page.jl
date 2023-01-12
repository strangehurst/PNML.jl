"""
$(TYPEDEF)
$(TYPEDFIELDS)

Contain all places, transitions & arcs. Pages are for visual presentation.
There must be at least 1 Page for a valid pnml model.
"""
struct Page{PNTD<:PnmlType, M, I, C, S} <: PnmlObject{PNTD}
    pntd::PNTD
    id::Symbol
    places::Vector{Place{PNTD, M, S}}
    refPlaces::Vector{RefPlace{PNTD}}
    transitions::Vector{Transition{PNTD, C}}
    refTransitions::Vector{RefTransition{PNTD}}
    arcs::Vector{Arc{PNTD, I}}
    declaration::Declaration

    #! XXX TODO Use AbstractTree?
    #!subpages::Vector{Any} #! XXX TODO
    subpages::Vector{Page{PNTD, M, I, C, S}} #! XXX TODO page_type(pntd)

    name::Maybe{Name}
    com::ObjectCommon

    # function Page(pntd::PnmlType,
    #             id::Symbol,
    #             places::Vector{Place}, refp::Vector{RefPlace},
    #             transitions::Vector{Transition}, reft::Vector{RefTransition},
    #             arcs::Vector{Arc},
    #             declare, pages, name,
    #             oc::ObjectCommon)

    #     isempty(places) && throw(ArgumentError("Page cannot have empty places"))
    #     isempty(transitions) && throw(ArgumentError("Page cannot have empty transitions"))
    #     isempty(arcs) && throw(ArgumentError("Page cannot have empty arcs"))

    #     new{typeof(pntd), typeof(declare)}(pntd, id,
    #                                        places, refp,
    #                                        transitions, reft,
    #                                        arcs,
    #                                        declare, pages, name, oc)
    # end
end

place_type(pntd::PnmlType) = Place{typeof(pntd),  marking_type(pntd), sort_type(pntd)}
transition_type(pntd::PnmlType) = Transition{typeof(pntd), condition_type(pntd)}
arc_type(pntd::PnmlType) = Arc{typeof(pntd), inscription_type(pntd)}
refplace_type(pntd::PnmlType) = RefPlace{typeof(pntd)}
reftransition_type(pntd::PnmlType) = RefTransition{typeof(pntd)}

# Note that declaration wraps a vector of AbstractDeclarations.
declarations(page::Page)   = declarations(page.declaration)
pages(page::Page)          = page.subpages
places(page::Page)         = page.places
transitions(page::Page)    = page.transitions
arcs(page::Page)           = page.arcs
refplaces(page::Page)      = page.refPlaces
reftransitions(page::Page) = page.refTransitions
common(page::Page)         = page.com

#! Subpages need to be traversed.
place(page::Page, id::Symbol)        = getfirst(Fix2(haspid, id), places(page))
place_ids(page::Page)                = map(pid, places(page))
has_place(page::Page, id::Symbol)    = any(Fix2(haspid, id), places(page))

marking(page::Page, placeid::Symbol) = marking(place(page, placeid))

currentMarkings(page::Page)           = currentMarkings(page, place_ids(page))
currentMarkings(page::Page, id_vec::Vector{Symbol}) = LVector((;[p=>marking(page, p)() for p in id_vec]...))

transition(page::Page, id::Symbol)      = getfirst(Fix2(haspid, id), transitions(page))
transition_ids(page::Page)              = map(pid, page.transitions)
has_transition(page::Page, id::Symbol)  = any(ispid(id), transition_ids(page))

condition(page::Page, trans_id::Symbol) = condition(transition(page, trans_id))
conditions(page::Page)                  = conditions(page, transition_ids(page))
conditions(page::Page, idvec::Vector{Symbol}) = LVector((;[t=>condition(page, t) for t in idvec]...))

arc(page::Page, id::Symbol)      = getfirst(Fix2(haspid, id), arcs(page))
arc_ids(page::Page)              = map(pid, arcs(page))
has_arc(page::Page, id::Symbol)  = any(ispid(id), arc_ids(page))
all_arcs(page::Page, id::Symbol) = filter(a -> source(a)===id || target(a)===id, arcs(page))
src_arcs(page::Page, id::Symbol) = filter(a -> source(a)===id, arcs(page))
tgt_arcs(page::Page, id::Symbol) = filter(a -> target(a)===id, arcs(page))

inscription(page::Page, arc_id::Symbol) = inscription(arc(page, arc_id))

refplace(page::Page, id::Symbol)      = getfirst(Fix2(haspid, id), refplaces(page))
refplace_ids(page::Page)              = map(pid, page.refPlaces)
has_refP(page::Page, id::Symbol)      = any(ispid(id), refplace_ids(page))

reftransition(page::Page, id::Symbol) = getfirst(Fix2(haspid, id), reftransitions(page))
reftransition_ids(page::Page)         = map(pid, page.refTransitions)
has_refT(page::Page, id::Symbol)      = any(ispid(id), reftransition_ids(page))

function Base.empty!(page::Page)
    empty!(page.places)
    empty!(page.refPlaces)
    empty!(page.transitions)
    empty!(page.refTransitions)
    empty!(page.arcs)
    empty!(page.declaration)
    !isnothing(page.subpages) && empty!(page.subpages)
    t = (tools ∘ common)(page)
    !isnothing(t) && empty!(t)
    l = labels(page.com)
    !isnothing(l) && empty!(l)
end
