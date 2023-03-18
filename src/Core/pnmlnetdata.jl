"""
Collect each of the `PnmlNodes`s & `Arc`s of a Petri Net Graph into one collection.
Accessed via pnml ID key or iterate over values of an `OrderedDict`.

In the 'pnml' specification there is a `Page` structure that can be removed by `flatten_pages!`,
removing some display-related information, leaving a functional Petri Net Graph as described
in this structure. It is intended to be a per-`PnmlNet` database that is mutated as each page
is parsed.
"""
struct PnmlNetData{PNTD <: PnmlType, M, I, C, S}
    #{PNTD, PL, TR, AR, RP, RT}
    pntd::PNTD
    place_dict::OrderedDict{Symbol, Place{PNTD,M,S}}
    transition_dict::OrderedDict{Symbol, Transition{PNTD,C}}
    arc_dict::OrderedDict{Symbol, Arc{PNTD,I}}
    refplace_dict::OrderedDict{Symbol, RefPlace{PNTD}}
    reftransition_dict::OrderedDict{Symbol, RefTransition{PNTD}}
end
PnmlNetData(pntd, pl, tr, ar, rp, rt) =
    PnmlNetData{typeof(pntd),
                typeof(pl), typeof(tr), typeof(ar),
                typeof(rp), typeof(rt)}(pntd, pl, tr, ar, rp, rt)

"""
ID sets for pages, places, arcs, et al. start as empty sets.

There is an ordered collection of `Pages` for each `PnmlNet`.
It is accompanied by a tree of ordered sets of keys (page ID symbols).

1st wave:
The `PnmlNet` and each `Page` use these key sets to represent their page-tree children.

Each `Page` "owns" the objects it places into the PnmlNetData database.
Access to subtrees may be useful, so the page-tree-node becomes a per-`Page` structure
of `OrderedSet`s of dictionary key symbols for each of: pages, net-nodes, arcs.
"""
@kwdef struct PnmlNetSets # PAGE TREE NODE is the set of page ids
    page_set::OrderedSet{Symbol} = OrderedSet{Symbol}()
    place_set::OrderedSet{Symbol} = OrderedSet{Symbol}()
    transition_set::OrderedSet{Symbol} = OrderedSet{Symbol}()
    arc_set::OrderedSet{Symbol} = OrderedSet{Symbol}()
    reftransition_set::OrderedSet{Symbol} = OrderedSet{Symbol}()
    refplace_set::OrderedSet{Symbol} = OrderedSet{Symbol}()
end
