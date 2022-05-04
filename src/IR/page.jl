"""
$(TYPEDEF)
$(TYPEDFIELDS)

Contain all places, transitions & arcs. Pages are for visual presentation.
There must be at least 1 Page for a valid pnml model.
"""
struct Page{PNTD<:PnmlType,D} <: PnmlObject
    id::Symbol
    places::Vector{Place}
    refPlaces::Vector{RefPlace}
    transitions::Vector{Transition}
    refTransitions::Vector{RefTransition}
    arcs::Vector{Arc}
    declaration::D
    subpages::Maybe{Vector{Page}}
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

function Base.empty!(page::Page)
    empty!(page.places)
    empty!(page.refPlaces)
    empty!(page.transitions)
    empty!(page.refTransitions)
    empty!(page.arcs)
    empty!(page.declaration)
    empty!(page.subpages)
    empty!(page.com)
end

