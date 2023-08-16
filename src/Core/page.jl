"""
$(TYPEDEF)
$(TYPEDFIELDS)

Contain all places, transitions & arcs. Pages are for visual presentation.
There must be at least 1 Page for a valid pnml model.

`PNTD` binds the other type parameters together to express a specific PNG.
See [`PnmlNet`](@ref)
"""
struct Page{PNTD <: PnmlType, P, T, A, RP, RT} <: AbstractPnmlObject{PNTD}
    pntd::PNTD
    id::Symbol
    declaration::Declaration
    name::Maybe{Name}
    com::ObjectCommon
    # pagedict and netdata do not overlap
    pagedict::OrderedDict{Symbol, Page{PNTD, P, T, A, RP, RT}} # Shared by net and its pages.
    netdata::PnmlNetData{PNTD, P, T, A, RP, RT} # Shared by net and its pages.
    netsets::PnmlNetKeys # This page's keys of items owned in netdata/pagedict.
    # Note: `PnmlNet` only has `page_set` because all net objects are attached to a `Page`.
    #TODO separate page id set here.
end

Page(pntd, i, dec, nam, c, pdict, ndata, nsets) =
    Page{typeof(pntd),
         place_type(pntd),
         transition_type(pntd),
         arc_type(pntd),
         refplace_type(pntd),
         reftransition_type(pntd)}(pntd, i, dec, nam, c, pdict, ndata, nsets)

nettype(::Page{T}) where {T<:PnmlType} = T

pagedict(p::Page) = p.pagedict
netdata(p::Page)  = p.netdata
netsets(p::Page)  = p.netsets

# Do not expect the page api to see much use, so it is not very efficient.
pages(page::Page)       = Iterators.filter(v -> pid(v) in page_idset(page), values(pagedict(page)))
places(page::Page)      = Iterators.filter(v -> pid(v) in place_idset(page), values(placedict(page)))
transitions(page::Page) = Iterators.filter(v -> pid(v) in transition_idset(page), values(transitiondict(page)))
arcs(page::Page)        = Iterators.filter(v -> pid(v) in arc_idset(page), values(arcdict(page)))
refplaces(page::Page)   = Iterators.filter(v -> pid(v) in refplace_idset(page), values(refplacedict(page)))
reftransitions(page::Page) = Iterators.filter(v -> pid(v) in reftransition_idset(page), values(reftransitiondict(page)))

declarations(page::Page) = declarations(page.declaration)
common(page::Page) = page.com

page_idset(page::Page) = page_idset(netsets(page)) # subpages of this page

place(page::Page, id::Symbol) = placedict(page)[id]
has_place(page::Page, id::Symbol) = (id in place_idset(page))

#marking(page::Page, placeid::Symbol) = marking(netdata(page).place_dict[placeid])
currentMarkings(page::Page) = LVector((; [pid(p) => marking(p)() for p in places(page)]...))

transition(page::Page, id::Symbol) = transitiondict(page)[id]
has_transition(page::Page, id::Symbol) = (id in transition_idset(page))

arc(page::Page, id::Symbol) = arcdict(page)[id]
has_arc(page::Page, id::Symbol) = (id in arc_idset(page))

# Currently, "all" means either end of the arc.
all_arcs(page::Page, id::Symbol) = Iterators.filter(a -> source(a) === id || target(a) === id, arcs(page))
src_arcs(page::Page, id::Symbol) = Iterators.filter(a -> source(a) === id, arcs(page))
tgt_arcs(page::Page, id::Symbol) = Iterators.filter(a -> target(a) === id, arcs(page))

inscription(page::Page, arc_id::Symbol) = inscription(arc(page, arc_id))

refplace(page::Page, id::Symbol) = refplacedict(page)[id]
has_refP(page::Page, id::Symbol) = (id in refplace_idset(page))

reftransition(page::Page, id::Symbol) = reftransitiondict(page)[id]
has_refT(page::Page, id::Symbol) = (id in reftransition_idset(page))

# When flattening, the only `common` that needs emptying is a `Page`'s.
function Base.empty!(page::Page)
    empty!(page.declaration)
    t = (tools ∘ common)(page)
    !isnothing(t) && empty!(t)
    l = (labels ∘ common)(page)
    !isnothing(l) && empty!(l)
end
