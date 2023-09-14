"""
$(TYPEDEF)
$(TYPEDFIELDS)

Collect each of the `PnmlNodes`s & `Arc`s of a Petri Net Graph into one collection.
Accessed via pnml ID key or iterate over values of an `OrderedDict`.

In the 'pnml' specification there is a `Page` structure that can be removed by `flatten_pages!`,
removing some display-related information, leaving a functional Petri Net Graph as described
in this structure. It is intended to be a per-`PnmlNet` database that is mutated as each page
is parsed.

See [`PnmlNetKeys`](@ref) for page-level pnml ID of "owners" net data.
"""
struct PnmlNetData{PNTD <: PnmlType, P, T, A, RP, RT}
    pntd::PNTD #
    place_dict::OrderedDict{Symbol, P}
    transition_dict::OrderedDict{Symbol, T}
    arc_dict::OrderedDict{Symbol, A}
    refplace_dict::OrderedDict{Symbol, RP}
    reftransition_dict::OrderedDict{Symbol, RT}
end
PnmlNetData(pntd) =
    PnmlNetData(pntd,
                OrderedDict{Symbol, place_type(pntd)}(),
                OrderedDict{Symbol, transition_type(pntd)}(),
                OrderedDict{Symbol, arc_type(pntd)}(),
                OrderedDict{Symbol, refplace_type(pntd)}(),
                OrderedDict{Symbol, reftransition_type(pntd)}())

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
    for (f,t) in [(placedict,"places"), (transitiondict,"transitions"), (arcdict,"arcs"),
                (refplacedict,"refplaces"), (reftransitiondict,"refTransitions")]
        println(io, length(f(pnd)), " ", t, ": ", (keys ∘ f)(pnd))
    end
end

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Per-page structure of `OrderedSet`s of pnml IDs for each "owned" `Page` and
[`AbstractPnmlObject`](@ref).
"""
@kwdef struct PnmlNetKeys
    page_set::OrderedSet{Symbol} = OrderedSet{Symbol}() # Subpages of page
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

# Usual use is for there to be a accessor in every user.
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
    for (func,tag) in [(page_idset,"pages"),
                    (place_idset,"places"), (transition_idset,"transitions"), (arc_idset,"arcs"),
                    (refplace_idset,"refplaces"), (reftransition_idset,"refTransitions")]
        println(io, length(func(pns)), " ", t, ": ", values(func(pns))) # needs spaces?
    end
end

function Base.show(io::IO, ::MIME"text/plain", pns::PnmlNetKeys)
    show(io, pns)
end
