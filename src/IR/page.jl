"""
$(TYPEDEF)
$(TYPEDFIELDS)

Contain all places, transitions & arcs. Pages are for visual presentation.
There must be at least 1 Page for a valid pnml model.
"""
struct Page{PNTD,D} <: PnmlObject{PNTD}
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
end

function Page(pntd::PNTD, id::Symbol, places, refp, transitions, reft,
                arcs, declare, pages, name, oc::ObjectCommon) where {PNTD<:PnmlType}
    Page{typeof(pntd),
         typeof(declare)}(id, places, refp, transitions, reft, arcs, declare, pages, name, oc)
end

# Note declaration wraps a vector of AbstractDeclarations.
declarations(page::Page) = declarations(page.declaration)
pages(page::Page) = page.subpages

places(page::Page)         = page.places
transitions(page::Page)    = page.transitions
arcs(page::Page)           = page.arcs
refplaces(page::Page)      = page.refPlaces
reftransitions(page::Page) = page.refTransitions

has_place(page::Page, id::Symbol) = any(x -> pid(x) === id, places(page))
place(page::Page, id::Symbol) = getfirst(x -> pid(x) === id, places(page))
place_ids(page::Page) = map(pid, places(page))
marking(page::Page, placeid::Symbol)             = marking(place(page, placeid))
initialMarking(page::Page)             = initialMarking(page, place_ids(page))
initialMarking(page::Page, id_vec::Vector{Symbol}) =
                                LVector((;[p=>marking(page, p)() for p in id_vec]...))

transition_ids(page::Page)             = map(pid, page.transitions)
has_transition(page::Page, id::Symbol)             = any(ispid(id), transition_ids(page))
transition(page::Page, id::Symbol)             = getfirst(x->pid(x)===id, transitions(page))
condition(page::Page, trans_id::Symbol)             = condition(transition(page, trans_id))
conditions(page::Page)             = conditions(page, transition_ids(page))
conditions(page::Page, idvec::Vector{Symbol}) = LVector((;[t=>condition(page, t) for t in idvec]...))

arc_ids(page::Page)             = map(pid, arcs(page))
has_arc(page::Page, id::Symbol)             = any(ispid(id), arc_ids(page))
arc(page::Page, id::Symbol)             = getfirst(x->pid(x)===id, arcs(page))
all_arcs(page::Page, id::Symbol)             = filter(a -> source(a)===id || target(a)===id, arcs(page))
src_arcs(page::Page, id::Symbol)             = filter(a -> source(a)===id, arcs(page))
tgt_arcs(page::Page, id::Symbol)             = filter(a -> target(a)===id, arcs(page))
inscription(page::Page, arc_id::Symbol)             = inscription(arc(page, arc_id))

has_refP(page::Page, ref_id::Symbol)             = any(x -> pid(x) === ref_id, refplaces(page))
has_refT(page::Page, ref_id::Symbol)             = any(x -> pid(x) === ref_id, reftransitions(page))
refplace_ids(page::Page)             = map(pid, page.refPlaces)
reftransition_ids(page::Page)             = map(pid, page.refTransitions)
refplace(page::Page, id::Symbol)             = getfirst(x -> pid(x) === id, refplaces(page))
reftransition(page::Page, id::Symbol)             = getfirst(x -> pid(x) === id, reftransitions(page))



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
