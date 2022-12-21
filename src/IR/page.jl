"""
$(TYPEDEF)
$(TYPEDFIELDS)

Contain all places, transitions & arcs. Pages are for visual presentation.
There must be at least 1 Page for a valid pnml model.
"""
struct Page{PNTD,D} <: PnmlObject{PNTD}
    pntd::PNTD
    id::Symbol
    places::Vector{Place{PNTD}}
    refPlaces::Vector{RefPlace{PNTD}}
    transitions::Vector{Transition{PNTD}}
    refTransitions::Vector{RefTransition{PNTD}}
    arcs::Vector{Arc{PNTD}}
    declaration::D
    subpages::Maybe{Vector{Page{PNTD}}}
    name::Maybe{Name}
    com::ObjectCommon

    function Page(pntd::PnmlType, id::Symbol, places, refp, transitions, reft, arcs,
                  declare, pages, name, oc::ObjectCommon)
        places isa Vector{Place} || throw(ArgumentError("Page places must be a Vector"))
        transitions isa Vector{Transition} || throw(ArgumentError("Page transitions must be a Vector"))
        arcs isa Vector{Arc} || throw(ArgumentError("Page arcs must be a Vector"))
        #isempty(places) && throw(ArgumentError("Page cannot have empty places"))
        #isempty(transitions) && throw(ArgumentError("Page cannot have empty places"))
        #isempty(places) && throw(ArgumentError("Page cannot have empty places"))

        #TODO Any more validation, perhaps configurable
        new{typeof(pntd), typeof(declare)}(pntd, id, places, refp, transitions, reft, arcs,
                                           declare, pages, name, oc)
    end
end


# Note that declaration wraps a vector of AbstractDeclarations.
declarations(page::Page)   = declarations(page.declaration)
pages(page::Page)          = page.subpages
places(page::Page)         = page.places
transitions(page::Page)    = page.transitions
arcs(page::Page)           = page.arcs
refplaces(page::Page)      = page.refPlaces
reftransitions(page::Page) = page.refTransitions

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
conditions(page::Page,
           idvec::Vector{Symbol}) = LVector((;[t=>condition(page, t) for t in idvec]...))

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
    has_tools(page.com) && empty!(page.com.tools)
    has_labels(page.com) && empty!(page.com.labels)
end
