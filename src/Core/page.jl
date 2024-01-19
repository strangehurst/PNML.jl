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
    graphics::Maybe{Graphics}
    tools::Vector{ToolInfo}
    labels::Vector{PnmlLabel}
    # pagedict and netdata do not overlap
    pagedict::OrderedDict{Symbol, Page{PNTD, P, T, A, RP, RT}} # Shared by net and its pages.
    netdata::PnmlNetData{PNTD, P, T, A, RP, RT} # Shared by net and its pages.
    netsets::PnmlNetKeys # This page's keys of items owned in netdata/pagedict.
    # Note: `PnmlNet` only has `page_set` because all net objects are attached to a `Page`.
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

#! Do not expect the page api to see much use, so it is not very efficient.
#! Also does not decend pagetree.
pages(page::Page)       = Iterators.filter(v -> in(pid(v), page_idset(page)), values(pagedict(page)))
places(page::Page)      = Iterators.filter(v -> in(pid(v), place_idset(page)), values(placedict(page)))
transitions(page::Page) = Iterators.filter(v -> in(pid(v), transition_idset(page)), values(transitiondict(page)))
arcs(page::Page)        = Iterators.filter(v -> in(pid(v), arc_idset(page)), values(arcdict(page)))
refplaces(page::Page)   = Iterators.filter(v -> in(pid(v), refplace_idset(page)), values(refplacedict(page)))
reftransitions(page::Page) = Iterators.filter(v -> in(pid(v), reftransition_idset(page)), values(reftransitiondict(page)))

declarations(page::Page) = declarations(page.declaration)

page_idset(page::Page) = page_idset(netsets(page)) # subpages of this page

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

# When flattening, the only `common` that needs emptying is a `Page`'s.
function Base.empty!(page::Page)
    empty!(page.declaration)
    t = tools(page)
    !isnothing(t) && empty!(t)
    l = labels(page)
    !isnothing(l) && empty!(l)
end


function Base.summary( page::Page)
    string(typeof(page)," id ", page.id, ", ",
           " name '", name(page), "', ",
           length(place_idset(page)), " places, ",
           length(transition_idset(page)), " transitions, ",
           length(arc_idset(page)), " arcs, ",
           isnothing(declarations(page)) ? 0 : length(declarations(page)), " declarations, ",
           length(refplace_idset(page)), " refP, ",
           length(reftransition_idset(page)), " refT, ",
           length(page_idset(page)), " subpages, ",
           has_graphics(page) ? " has graphics " : " no graphics",
           length(tools(page)), " tools, ",
           length(labels(page)), " labels"
           )
end

function show_page_field(io::IO, label::AbstractString, x)
    println(io, indent(io), label)
    if !isnothing(x) && length(x) > 0
        show(inc_indent(io), MIME"text/plain"(), x)
        print(io, "\n")
    end
end

function Base.show(io::IO, page::Page)
    #TODO Add support for :trim and :compact
    println(io, indent(io), summary(page))
    # Start indent here. Will indent subpages.
    inc_io = inc_indent(io)

    show_page_field(inc_io, "places:",         place_idset(page))
    show_page_field(inc_io, "transitions:",    transition_idset(page))
    show_page_field(inc_io, "arcs:",           arc_idset(page))
    show_page_field(inc_io, "declaration:",    declarations(page))
    show_page_field(inc_io, "refPlaces:",      refplace_idset(page))
    show_page_field(inc_io, "refTransitions:", reftransition_idset(page))
    show_page_field(inc_io, "subpages:",       page_idset(page))
end
