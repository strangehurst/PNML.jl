"""
$(TYPEDEF)
$(TYPEDFIELDS)

Contain all places, transitions & arcs. Pages are for visual presentation.
There must be at least 1 Page for a valid pnml model.
"""
struct Page{PNTD<:PnmlType,M,I,C,S} <: AbstractPnmlObject{PNTD}
    pntd::PNTD
    id::Symbol

    declaration::Declaration
    name::Maybe{Name}
    com::ObjectCommon

    pagedict::OrderedDict{Symbol,Page{PNTD, M, I, C, S}}  #! Shared by net and its pages

    #place_dict::OrderedDict{Symbol, Place{PNTD,M,S}} # Was: places::Vector{Place{PNTD,M,S}}
    #refPlace_dict::OrderedDict{Symbol, RefPlace{PNTD}}
    #transition_dict::OrderedDict{Symbol, Transition{PNTD,C}}
    #refTransition_dict::OrderedDict{Symbol, RefTransition{PNTD}}
    #arc_dict::OrderedDict{Symbol, Arc{PNTD,I}}

    pageset::OrderedSet{Symbol} # PAGE TREE NODE is set of page ids
    # TODO add id sets for place, arc, et al. Share dicts among all pages & net?
    #place_set::OrderedSet{Symbol}
    #refPlace_set::OrderedSet{Symbol}
    #transition_set::OrderedSet{Symbol}
    #refTransition_set::OrderedSet{Symbol}
    #arc_set::OrderedSet{Symbol}
end

nettype(::Page{T}) where {T<:PnmlType} = T

# Note that declaration wraps a vector of AbstractDeclarations.
declarations(page::Page) = declarations(page.declaration)

#! pages(page::Page) = values(page.pagedict) # iterator

places(page::Page)      = values(page.place_dict)
transitions(page::Page) = values(page.transition_dict)
arcs(page::Page)        = values(page.arc_dict)
refplaces(page::Page)   = values(page.refPlace_dict)
reftransitions(page::Page) = values(page.refTransition_dict)

common(page::Page) = page.com

place(page::Page, id::Symbol) = page.place_dict[id]
place_ids(page::Page) = keys(page.place_dict) # map(pid, places(page))
has_place(page::Page, id::Symbol) = haskey(page.place_dict, id)

marking(page::Page, placeid::Symbol) = marking(page.place_dict[placeid])

currentMarkings(page::Page) = LVector((; [p => marking(page, p)() for p in place_ids(page)]...))

transition(page::Page, id::Symbol) = page.transition_dict[id]
transition_ids(page::Page) = keys(page.transition_dict)
has_transition(page::Page, id::Symbol) = haskey(page.transition_dict, id)

condition(page::Page, trans_id::Symbol) = condition(transition(page, trans_id))
conditions(page::Page) =  LVector((; [t => condition(page, t) for t in transition_ids(page)]...))

arc(page::Page, id::Symbol) = page.arc_dict[id]
arc_ids(page::Page) = keys(page.arc_dict)
has_arc(page::Page, id::Symbol) = haskey(page.arc_dict, id)

# Currently, "all" means either end of the arc.
all_arcs(page::Page, id::Symbol) = filter(a -> source(a) === id || target(a) === id, arcs(page))
src_arcs(page::Page, id::Symbol) = filter(a -> source(a) === id, arcs(page))
tgt_arcs(page::Page, id::Symbol) = filter(a -> target(a) === id, arcs(page))

inscription(page::Page, arc_id::Symbol) = inscription(arc(page, arc_id))

refplace(page::Page, id::Symbol) = page.refPlace_dict[id]
refplace_ids(page::Page) = keys(page.refPlace_dict)
has_refP(page::Page, id::Symbol) = haskey(page.refPlace_dict, id)

reftransition(page::Page, id::Symbol) = page.refTransition_dict[id]
reftransition_ids(page::Page) = keys(page.refTransition_dict)
has_refT(page::Page, id::Symbol) = haskey(page.refTransition_dict, id)

function Base.empty!(page::Page)
    empty!(page.place_dict)
    empty!(page.refPlace_dict)
    empty!(page.transition_dict)
    empty!(page.refTransition_dict)
    empty!(page.arc_dict)
    empty!(page.declaration)
    !isnothing(page.pageset) && empty!(page.pageset) #! PAGE TREE NODE
    t = (tools ∘ common)(page)
    !isnothing(t) && empty!(t)
    l = (labels ∘ common)(page)
    !isnothing(l) && empty!(l)
end
