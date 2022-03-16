"""
$(TYPEDEF)
$(TYPEDFIELDS)

Contain all places, transitions & arcs. Pages are for visual presentation.
There must be at least 1 Page for a valid pnml model.
"""
struct Page{PNTD<:PnmlType} <: PnmlObject
    id::Symbol
    places::Vector{Place}
    refPlaces::Vector{RefPlace}
    transitions::Vector{Transition}
    refTransitions::Vector{RefTransition}
    arcs::Vector{Arc}
    declaration::Declaration
    subpages::Maybe{Vector{Page}}
    com::ObjectCommon
end

"""
$(TYPEDSIGNATURES)
"""
function Page(d::PnmlDict, pntd = PnmlCore())
    Page{typeof(pntd)}(
        d[:id],
        d[:places], d[:refP],
        d[:trans], d[:refT],
        d[:arcs],
        d[:declaration],
        d[:pages],
        ObjectCommon(d))
end

declarations(page::Page) = declarations(page.declaration)

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

