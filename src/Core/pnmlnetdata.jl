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

placedict(d::PnmlNetData)         = d.place_dict
transitiondict(d::PnmlNetData)    = d.transition_dict
arcdict(d::PnmlNetData)           = d.arc_dict
refplacedict(d::PnmlNetData)      = d.refplace_dict
reftransitiondict(d::PnmlNetData) = d.reftransition_dict

placedict(x)         = placedict(netdata(x))
transitiondict(x)    = transitiondict(netdata(x))
arcdict(x)           = arcdict(netdata(x))
refplacedict(x)      = refplacedict(netdata(x))
reftransitiondict(x) = reftransitiondict(netdata(x))

nplace(d::PnmlNetData)         = length(placedict(d))
ntransition(d::PnmlNetData)    = length(transitiondict(d))
narc(d::PnmlNetData)           = length(arcdict(d))
nrefplace(d::PnmlNetData)      = length(refplacedict(d))
nreftransition(d::PnmlNetData) = length(reftransitiondict(d))

function tunesize!(d::PnmlNetData;
                    nplace::Int = 32,
                    ntransition::Int = 32,
                    narc::Int = 32,
                    npref::Int = 1, # References only matter when npage > 1.
                    ntref::Int = 1)

    sizehint!(d.place_dict, nplace)
    sizehint!(d.transition_dict, ntransition)
    sizehint!(d.arc_dict, narc)
    sizehint!(d.reftransition_dict, ntref)
    sizehint!(d.refplace_dict, npref)
end

function Base.show(io::IO, pnd::PnmlNetData)
    print(io, nameof(typeof(pnd)), "(",)
    show(io, pnd.pntd); println(io, ", ")
    io = inc_indent(io)
    for (t, f) in (("places", placedict),
                  ("transitions", transitiondict),
                  ("arcs", arcdict),
                  ("refplaces", refplacedict),
                  ("refTransitions", reftransitiondict))
        print(io, indent(io), length(f(pnd)), " ", t, ": ")
        iio = inc_indent(io)
        for (i,k) in enumerate(keys(f(pnd)))
            show(io, k); print(io, ", ")
            if (i < length(f(pnd))) && (i % 25 == 0)
                print(iio, '\n', indent(iio))
            end
        end
        println(io)
    end
    print(io, ")")
end

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Per-page structure of `OrderedSet`s of pnml IDs for each "owned" `Page` and other
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

#
page_idset(x)          = page_idset(netsets(x))
place_idset(x)         = place_idset(netsets(x))
transition_idset(x)    = transition_idset(netsets(x))
arc_idset(x)           = arc_idset(netsets(x))
reftransition_idset(x) = reftransition_idset(netsets(x))
refplace_idset(x)      = refplace_idset(netsets(x))

function tunesize!(s::PnmlNetKeys;
                   npage::Int = 1, # Usually just 1 page per net.
                   nplace::Int = 32,
                   ntransition::Int = 32,
                   narc::Int = 32,
                   npref::Int = 1, # References only matter when npage > 1.
                   ntref::Int = 1)
    sizehint!(s.page_set, npage)
    sizehint!(s.place_set, nplace)
    sizehint!(s.transition_set, ntransition)
    sizehint!(s.arc_set, narc)
    sizehint!(s.reftransition_set, ntref)
    sizehint!(s.refplace_set, npref)
end

#-------------------
Base.summary(io::IO, pns::PnmlNetKeys) = print(io, summary(pns))
function Base.summary(pns::PnmlNetKeys)
    string(length(page_idset(pns)), " pages, ",
            length(place_idset(pns)), " places, ",
            length(transition_idset(pns)), " transitions, ",
            length(arc_idset(pns)), " arcs, ",
            length(refplace_idset(pns)), " refPlaces, ",
            length(reftransition_idset(pns)), " refTransitions, ",
        )::String
end

function Base.show(io::IO, pns::PnmlNetKeys)
    for (tag, func) in (("pages", page_idset),
                        ("places", place_idset),
                        ("transitions", transition_idset),
                        ("arcs", arc_idset),
                        ("refplaces", refplace_idset),
                        ("refTransitions", reftransition_idset))
        print(io, indent(io), length(func(pns)), " ", tag, ": ")
        iio = inc_indent(io)
        for (i,k) in enumerate((values ∘ func)(pns))
            print(io, repr(k), ", ")
            if (i < length(func(pns))) && (i % 25 == 0)
                print(iio, '\n', indent(iio))
            end
        end
        println(io)
    end
end
