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

