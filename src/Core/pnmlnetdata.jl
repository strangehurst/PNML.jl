"""
Collect each of the `PnmlNodes`s & `Arc`s of a Petri Net Graph into one collection.
Accessed via pnml ID key or iterate over values of an `OrderedDict`.

In the 'pnml' specification there is a `Page` structure that can be removed by `flatten_pages!`,
removing some display-related information, leaving a functional Petri Net Graph as described
in this structure. It is intended to be a per-`PnmlNet` database that is mutated as each page
is parsed.

See [`PnmlNetKeys`](@ref) for page-level pnml ID of "owners" net data.
"""
struct PnmlNetData{PNTD <: PnmlType, M, I, C, S}
    pntd::PNTD #
    place_dict::OrderedDict{Symbol, Place{PNTD,M,S}}
    transition_dict::OrderedDict{Symbol, Transition{PNTD,C}}
    arc_dict::OrderedDict{Symbol, Arc{PNTD,I}}
    refplace_dict::OrderedDict{Symbol, RefPlace{PNTD}}
    reftransition_dict::OrderedDict{Symbol, RefTransition{PNTD}}
end
PnmlNetData(pntd, pl_dict, tr_dict, ar_dict, rp_dict, rt_dict) =
    PnmlNetData{typeof(pntd),
                marking_type(pntd),
                inscription_type(pntd),
                condition_type(pntd),
                sort_type(pntd)}(pntd, pl_dict, tr_dict, ar_dict, rp_dict, rt_dict)
#
placedict(d::PnmlNetData) = d.place_dict
transitiondict(d::PnmlNetData) = d.transition_dict
arcdict(d::PnmlNetData) = d.arc_dict
refplacedict(d::PnmlNetData) = d.refplace_dict
reftransitiondict(d::PnmlNetData) = d.reftransition_dict

placedict(x) = placedict(netdata(x))
transitiondict(x) = transitiondict(netdata(x))
arcdict(x) = arcdict(netdata(x))
refplacedict(x) = refplacedict(netdata(x))
reftransitiondict(x) = reftransitiondict(netdata(x))

function Base.show(io::IO, pnd::PnmlNetData)
    length(placedict(pnd)) > 0 && print(io, "places: ", (sort ∘ collect ∘ keys ∘ placedict)(pnd), ", ")
    length(transitiondict(pnd)) > 0 && print(io, "transitions: ", (sort ∘ collect ∘ keys ∘ transitiondict)(pnd), ", ")
    length(arcdict(pnd)) > 0 && print(io, "arcs: ", (sort ∘ collect ∘ keys ∘ arcdict)(pnd), ", ")
    length(refplacedict(pnd)) > 0 && print(io, "refplaces: ", (sort ∘ collect ∘ keys ∘ refplacedict)(pnd), ", ")
    length(reftransitiondict(pnd)) > 0 && print(io, "refTransitions: ", (sort ∘ collect ∘ keys ∘ reftransitiondict)(pnd), ", ")
end

"""
ID sets for pages, places, arcs, et al. start as empty sets.

There is one collection of `Pages` for each `PnmlNet` that is not part of `PnmlNetData`: `pagedict`.
It is accompanied by a tree of ordered sets of page ID symbols: `page_set`.

1st wave:
The `PnmlNet` and each `Page` use these key sets to represent their page-tree children.

Each `Page` "owns" the objects it places into the PnmlNetData database.
Allows for interactive display (NOT IMPLEMENTD) and testing.

Access to subtrees may be useful, so the page-tree-node becomes a per-page structure
of `OrderedSet`s of pnml IDs for each "owned" [`AbstractPnmlObject`](@ref)
"""
@kwdef struct PnmlNetKeys # PAGE TREE NODE is the set of page ids
    page_set::OrderedSet{Symbol} = OrderedSet{Symbol}() #! Subpages of page
    place_set::OrderedSet{Symbol} = OrderedSet{Symbol}()
    transition_set::OrderedSet{Symbol} = OrderedSet{Symbol}()
    arc_set::OrderedSet{Symbol} = OrderedSet{Symbol}()
    reftransition_set::OrderedSet{Symbol} = OrderedSet{Symbol}()
    refplace_set::OrderedSet{Symbol} = OrderedSet{Symbol}()
end

page_idset(s::PnmlNetKeys) = s.page_set
place_idset(s::PnmlNetKeys) = s.place_set
transition_idset(s::PnmlNetKeys) = s.transition_set
arc_idset(s::PnmlNetKeys) = s.arc_set
reftransition_idset(s::PnmlNetKeys) = s.reftransition_set
refplace_idset(s::PnmlNetKeys) = s.refplace_set

# page_idset(tup::NamedTuple) = page_idset(tup.netsets)
# place_idset(tup::NamedTuple) = (place_idsettup.netsets)
# transition_idset(tup::NamedTuple) = transition_idset(tup.netsets)
# arc_idset(tup::NamedTuple) = arc_idset(tup.netsets)
# reftransition_idset(tup::NamedTuple) = reftransition_idset(tup.netsets)
# refplace_idset(tup::NamedTuple) = trefplace_idset(up.netsets)

page_idset(x)          = page_idset(netsets(x))
place_idset(x)         = place_idset(netsets(x))
transition_idset(x)    = transition_idset(netsets(x))
arc_idset(x)           = arc_idset(netsets(x))
reftransition_idset(x) = reftransition_idset(netsets(x))
refplace_idset(x)      = refplace_idset(netsets(x))

#-------------------
Base.summary(io::IO, pns::PnmlNetKeys) = print(io, summary(pns))
function Base.summary(pns::PnmlNetKeys)
    string(length(page_idset(pns)), " pages, ",
            length(place_idset(pns)), " places, ",
            length(transition_idset(pns)), " transitions, ",
            length(arc_idset(pns)), " arcs, ",
            length(refplac_ideset(pns)), " refPlaces, ",
            length(reftransition_idset(pns)), " refTransitions, ",
        )
end

function Base.show(io::IO, pns::PnmlNetKeys)
    length(page_idset(pns)) > 0 &&
        print(io, "pages: ", (sort ∘ collect ∘ values ∘ page_idset)(pns), ", ")
    length(place_idset(pns)) > 0 &&
        print(io, "places: ", (sort ∘ collect ∘ values ∘ place_idset)(pns), ", ")
    length(transition_idset(pns)) > 0 &&
        print(io, "transitions: ", (sort ∘ collect ∘ values ∘ transition_idset)(pns), ", ")
    length(arc_idset(pns)) > 0 &&
        print(io, "arcs: ", (sort ∘ collect ∘ values ∘ arc_idset)(pns), ", ")
    length(refplace_idset(pns)) > 0 &&
        print(io, "refplaces: ", (sort ∘ collect ∘ values ∘ refplace_idset)(pns), ", ")
    length(reftransition_idset(pns)) > 0 &&
        print(io, "refTransitions: ", (sort ∘ collect ∘ values ∘ reftransition_idset)(pns), ", ")
end

function Base.show(io::IO, ::MIME"text/plain", pns::PnmlNetKeys)
    show(io, pns)
end
