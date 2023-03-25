"""
$(TYPEDEF)
$(TYPEDFIELDS)

Contain all places, transitions & arcs. Pages are for visual presentation.
There must be at least 1 Page for a valid pnml model.
"""
struct Page{PNTD <: PnmlType, M, I, C, S} <: AbstractPnmlObject{PNTD}
    #! {M, I, C, S} # PL, TR, AR, RP, RT}
    pntd::PNTD
    id::Symbol
    declaration::Declaration
    name::Maybe{Name}
    com::ObjectCommon
    pagedict::OrderedDict{Symbol, Page{PNTD, M, I, C, S}} #! Shared by net and its pages
    netdata::PnmlNetData{PNTD, M, I, C, S}    #! Shared by net and its pages
    netsets::PnmlNetSets

end

#!Page(pntd, pl, tr, ar, rp, rt) =
Page(pntd, i, dec, nam, pdict, ndata, nsets) =
Page{typeof(pntd), marking_type(pntd), inscription_type(pntd),
         condition_typeof(pntd), sort_type(pntd)}(pntd, i, dec, nam, pdict, ndata, nsets)

nettype(::Page{T}) where {T<:PnmlType} = T

# Note that declaration wraps a vector of AbstractDeclarations.
declarations(page::Page) = declarations(page.declaration)
# subpages
#!pages(page::Page) = [page.pagedict[id] for id in page.netsets.page_set] #! Vector not iterator
pages(page::Page) = Iterators.filter(v -> pid(v) in page.netsets.page_set, values(page.pagedict)) # iterator

netdata(p::Page) = p.netdata

places(page::Page)      = Iterators.filter(v -> pid(v) in page.netsets.place_set, values(netdata(page).place_dict))
transitions(page::Page) = Iterators.filter(v -> pid(v) in page.netsets.transition_set, values(netdata(page).transition_dict))
arcs(page::Page)        = Iterators.filter(v -> pid(v) in page.netsets.arc_set, values(netdata(page).arc_dict))
refplaces(page::Page)   = Iterators.filter(v -> pid(v) in page.netsets.refplace_set, values(netdata(page).refplace_dict))
reftransitions(page::Page) = Iterators.filter(v -> pid(v) in page.netsets.reftransition_set, values(netdata(page).reftransition_dict))

common(page::Page) = page.com

place(page::Page, id::Symbol) = netdata(page).place_dict[id]
place_ids(page::Page) = page.netsets.place_set
has_place(page::Page, id::Symbol) = (id in page.netsets.place_set)

#marking(page::Page, placeid::Symbol) = marking(netdata(page).place_dict[placeid])
currentMarkings(page::Page) = LVector((; [pid(p) => marking(p)() for p in places(page)]...))

transition(page::Page, id::Symbol) = netdata(page).transition_dict[id]
transition_ids(page::Page) = page.netsets.transition_set
has_transition(page::Page, id::Symbol) = (id in page.netsets.transition_set)

arc(page::Page, id::Symbol) = netdata(page).arc_dict[id]
arc_ids(page::Page) = page.netsets.arc_set
has_arc(page::Page, id::Symbol) = (id in page.netsets.arc_set)

# Currently, "all" means either end of the arc.
all_arcs(page::Page, id::Symbol) = Iterators.filter(a -> source(a) === id || target(a) === id, arcs(page))
src_arcs(page::Page, id::Symbol) = Iterators.filter(a -> source(a) === id, arcs(page))
tgt_arcs(page::Page, id::Symbol) = Iterators.filter(a -> target(a) === id, arcs(page))

inscription(page::Page, arc_id::Symbol) = inscription(arc(page, arc_id))

refplace(page::Page, id::Symbol) = netdata(page).refplace_dict[id]
refplace_ids(page::Page) = page.netsets.refplace_set
has_refP(page::Page, id::Symbol) = (id in page.netsets.refplace_set)

reftransition(page::Page, id::Symbol) = netdata(page).reftransition_dict[id]
reftransition_ids(page::Page) = page.netsets.reftransition_set
has_refT(page::Page, id::Symbol) = (id in page.netsets.reftransition_set)

function Base.empty!(page::Page)
    #empty!(netdata(page).place)
    #empty!(netdata(page).refplace)
    #empty!(netdata(page).transition)
    #empty!(netdata(page).reftransition)
    #empty!(netdata(page).arc)
    empty!(page.declaration)
    # !isnothing(page.pageset) && empty!(page.pageset) #! PAGE TREE NODE
    t = (tools ∘ common)(page)
    !isnothing(t) && empty!(t)
    l = (labels ∘ common)(page)
    !isnothing(l) && empty!(l)
end
