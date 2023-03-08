"""
$(TYPEDEF)
$(TYPEDFIELDS)

Contain all places, transitions & arcs. Pages are for visual presentation.
There must be at least 1 Page for a valid pnml model.
"""
struct Page{PNTD<:PnmlType,M,I,C,S} <: AbstractPnmlObject{PNTD}
    pntd::PNTD
    id::Symbol
    #!places::Vector{Place{PNTD,M,S}}
    placedict::OrderedDict{Symbol, Place{PNTD,M,S}}
    refPlaces::Vector{RefPlace{PNTD}} # OrderedDict{Symbol, RefPlace{PNTD}}
    transitions::Vector{Transition{PNTD,C}} # OrderedDict{Symbol, Transition{PNTD,C}}
    refTransitions::Vector{RefTransition{PNTD}} # OrderedDict{Symbol, RefTransition{PNTD}}
    arcs::Vector{Arc{PNTD,I}} # OrderedDict{Symbol, Arc{PNTD,I}}
    declaration::Declaration
    name::Maybe{Name}
    com::ObjectCommon

    pagedict::OrderedDict{Symbol,Page{PNTD, M, I, C, S}}  #! Shared by net and its pages
    pageset::OrderedSet{Symbol} # PAGE TREE NODE is set of page ids
end

nettype(::Page{T}) where {T<:PnmlType} = T

# Note that declaration wraps a vector of AbstractDeclarations.
declarations(page::Page) = declarations(page.declaration)

#! pages(page::Page) = values(page.pagedict) # iterator

places(page::Page) = values(page.placedict)
transitions(page::Page) = page.transitions
arcs(page::Page) = page.arcs
refplaces(page::Page) = page.refPlaces
reftransitions(page::Page) = page.refTransitions
common(page::Page) = page.com

place(page::Page, id::Symbol) = page.placedict[id]
place_ids(page::Page) = keys(page.placedict) # map(pid, places(page))
has_place(page::Page, id::Symbol) = any(==(id), keys(page.placedict))

marking(page::Page, placeid::Symbol) = marking(page.placedict[placeid])

currentMarkings(page::Page) = currentMarkings(page, place_ids(page))
currentMarkings(page::Page, id_vec::Vector{Symbol}) = LVector((; [p => marking(page, p)() for p in id_vec]...))

transition(page::Page, id::Symbol) = getfirst(Fix2(haspid, id), transitions(page))
transition_ids(page::Page) = map(pid, page.transitions)
has_transition(page::Page, id::Symbol) = any(ispid(id), transition_ids(page))

condition(page::Page, trans_id::Symbol) = condition(transition(page, trans_id))
conditions(page::Page) = conditions(page, transition_ids(page))
conditions(page::Page, idvec::Vector{Symbol}) = LVector((; [t => condition(page, t) for t in idvec]...))

arc(page::Page, id::Symbol) = getfirst(Fix2(haspid, id), arcs(page))
arc_ids(page::Page) = map(pid, arcs(page))
has_arc(page::Page, id::Symbol) = any(ispid(id), arc_ids(page))
all_arcs(page::Page, id::Symbol) = filter(a -> source(a) === id || target(a) === id, arcs(page))
src_arcs(page::Page, id::Symbol) = filter(a -> source(a) === id, arcs(page))
tgt_arcs(page::Page, id::Symbol) = filter(a -> target(a) === id, arcs(page))

inscription(page::Page, arc_id::Symbol) = inscription(arc(page, arc_id))

refplace(page::Page, id::Symbol) = getfirst(Fix2(haspid, id), refplaces(page))
refplace_ids(page::Page) = map(pid, page.refPlaces)
has_refP(page::Page, id::Symbol) = any(ispid(id), refplace_ids(page))

reftransition(page::Page, id::Symbol) = getfirst(Fix2(haspid, id), reftransitions(page))
reftransition_ids(page::Page) = map(pid, page.refTransitions)
has_refT(page::Page, id::Symbol) = any(ispid(id), reftransition_ids(page))

function Base.empty!(page::Page)
    empty!(page.placedict)
    empty!(page.refPlaces)
    empty!(page.transitions)
    empty!(page.refTransitions)
    empty!(page.arcs)
    empty!(page.declaration)
    !isnothing(page.pageset) && empty!(page.pageset) #! PAGE
    t = (tools ∘ common)(page)
    !isnothing(t) && empty!(t)
    l = (labels ∘ common)(page)
    !isnothing(l) && empty!(l)
end
