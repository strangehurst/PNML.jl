"""
$(TYPEDEF)
$(TYPEDFIELDS)

Contain all places, transitions & arcs. Pages are for visual presentation.
There must be at least 1 Page for a valid pnml model.

`PNTD` binds the other type parameters together to express a specific PNG.
See [`PnmlNet`](@ref)
"""
mutable struct Page{PNTD <: PnmlType, P, T, A, RP, RT} <: AbstractPnmlObject
    pntd::PNTD
    id::Symbol
    declaration::Declaration
    namelabel::Maybe{Name}
    graphics::Maybe{Graphics}
    tools::Maybe{Vector{ToolInfo}}
    labels::Maybe{Vector{PnmlLabel}}
    # Note: pagedict and netdata do not overlap.
    pagedict::OrderedDict{Symbol, Page{PNTD, P, T, A, RP, RT}} # All pages. Shared by net and its pages.
    netdata::PnmlNetData{PNTD} # !, P, T, A, RP, RT} # All Places, Arcs, etc. Shared by net and its pages.
    netsets::PnmlNetKeys # This page's keys of items owned in netdata/pagedict. Not shared.
    # Note: `PnmlNet` only has `page_set` because all PNML net Objects are attached to a `Page`. And there must be one `Page`.
    # There could be >1 nets. `netdata` is ordered, `netsets` are unordered.
end

Page(pntd, i, dec, nam, c, pdict, ndata, nsets) =
    Page{typeof(pntd), #! ? typeof ?
         place_type(pntd),
         transition_type(pntd),
         arc_type(pntd),
         refplace_type(pntd),
         reftransition_type(pntd)}(pntd, i, dec, nam, c, pdict, ndata, nsets)

nettype(::Page{T}) where {T<:PnmlType} = T

pagedict(p::Page) = p.pagedict
netdata(p::Page)  = p.netdata
netsets(p::Page)  = p.netsets

placedict(p::Page)         = placedict(netdata(p))
transitiondict(p::Page)    = transitiondict(netdata(p))
arcdict(p::Page)           = arcdict(netdata(p))
refplacedict(p::Page)      = refplacedict(netdata(p))
reftransitiondict(p::Page) = reftransitiondict(netdata(p))

#! Do not expect the page api to see much use, so it is likely not very efficient.
#! Also does not decend pagetree. And otherwise limited functionality.
pages(page::Page)       = Iterators.filter(v -> in(pid(v), page_idset(page)), values(pagedict(page)))
places(page::Page)      = Iterators.filter(v -> in(pid(v), place_idset(page)), values(placedict(page)))
transitions(page::Page) = Iterators.filter(v -> in(pid(v), transition_idset(page)), values(transitiondict(page)))
arcs(page::Page)        = Iterators.filter(v -> in(pid(v), arc_idset(page)), values(arcdict(page)))
refplaces(page::Page)   = Iterators.filter(v -> in(pid(v), refplace_idset(page)), values(refplacedict(page)))
reftransitions(page::Page) = Iterators.filter(v -> in(pid(v), reftransition_idset(page)), values(reftransitiondict(page)))

decldict(page::Page) = decldict(page.declaration) # Forward to the collection object.

page_idset(page::Page)          = page_idset(netsets(page)) # subpages of this page
"Return netsets place_idset"
place_idset(page::Page)         = place_idset(netsets(page))
transition_idset(page::Page)    = transition_idset(netsets(page))
arc_idset(page::Page)           = arc_idset(netsets(page))
reftransition_idset(page::Page) = reftransition_idset(netsets(page))
refplace_idset(page::Page)      = refplace_idset(netsets(page))

place(page::Page, id::Symbol) = placedict(page)[id]
has_place(page::Page, id::Symbol) = in(id, place_idset(page))

transition(page::Page, id::Symbol) = transitiondict(page)[id]
has_transition(page::Page, id::Symbol) = in(id, transition_idset(page))

arc(page::Page, id::Symbol) = arcdict(page)[id]
has_arc(page::Page, id::Symbol) = in(id, arc_idset(page))

refplace(page::Page, id::Symbol)     = refplacedict(page)[id]
has_refplace(page::Page, id::Symbol) = in(id, refplace_idset(page))

reftransition(page::Page, id::Symbol)     = reftransitiondict(page)[id]
has_reftransition(page::Page, id::Symbol) = in(id, reftransition_idset(page))

function Base.show(io::IO, page::Page)
    #TODO Add support for :trim and :compact
    print(io, "Page{", nettype(page),"}("),
    show(io, pid(page)); print(io, ", ")
    show(io, name(page)); print(io, ", ")
    println(io)
    iio = inc_indent(io)    # Will indent subpages.
    print(iio, indent(iio), "places: ",       repr(place_idset(page)), ",\n");
    print(iio, indent(iio), "transitions: ",  repr(transition_idset(page)), ",\n");
    print(iio, indent(iio), "arcs: ",         repr(arc_idset(page)), ",\n");
    print(iio, indent(iio), "refPlaces:",     repr(refplace_idset(page)), ",\n");
    print(iio, indent(iio), "refTransitions: ", repr(reftransition_idset(page)), ",\n");
    print(iio, indent(iio), "subpages: ",     repr(page_idset(page)), ",\n");
    print(iio, indent(iio), "declarations: ", "repr(decldict(page)) suppressed", ",\n");
    print(io, ")")
end

function verify(page::Page; verbose::Bool = CONFIG[].verbose)
    #verbose && println("verify Page $(pid(page))"); flush(stdout)
    errors = String[]
    verify!(errors, page; verbose)
    isempty(errors) ||
      error("verify(page) error(s): ", join(errors, ",\n "))
    return true
end
function verify!(errors, page::Page; verbose::Bool = CONFIG[].verbose)
    # TODO
     return nothing
end
