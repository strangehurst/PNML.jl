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

nplaces(d::PnmlNetData)         = length(placedict(d))
ntransitions(d::PnmlNetData)    = length(transitiondict(d))
narcs(d::PnmlNetData)           = length(arcdict(d))
nrefplaces(d::PnmlNetData)      = length(refplacedict(d))
nreftransitions(d::PnmlNetData) = length(reftransitiondict(d))

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

function print_decl_keys(io::IO, name::AbstractString, dict)
    print(io, indent(io), length(dict), " ", name, ": ")
    iio = inc_indent(io)
    for (i,k) in enumerate(keys(dict))
        show(io, k); print(io, ", ")
        if (i < length(dict)) && (i % 25 == 0)
            print(iio, '\n', indent(iio))
        end
    end
    println(io)
end

function Base.show(io::IO, pnd::PnmlNetData)
    print(io, nameof(typeof(pnd)), "(",)
    show(io, pnd.pntd); println(io, ", ")
    io = inc_indent(io)
    for (tag, dict) in (("places", placedict),
                  ("transitions", transitiondict),
                  ("arcs", arcdict),
                  ("refplaces", refplacedict),
                  ("refTransitions", reftransitiondict))

        print_decl_keys(io, tag, dict(pnd))
    end
    print(io, ")")
end

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Per-page structure of `Set`s of pnml IDs for each "owned" `Page` and other
[`AbstractPnmlObject`](@ref).
"""
@kwdef struct PnmlNetKeys
    page_set::Set{Symbol} = Set{Symbol}() # Subpages of page
    place_set::Set{Symbol} = Set{Symbol}()
    transition_set::Set{Symbol} = Set{Symbol}()
    arc_set::Set{Symbol} = Set{Symbol}()
    reftransition_set::Set{Symbol} = Set{Symbol}()
    refplace_set::Set{Symbol} = Set{Symbol}()
end

page_idset(s::PnmlNetKeys) = s.page_set
"Return an `Set{Symbol}, should it be an iterator?"
place_idset(s::PnmlNetKeys) = s.place_set
transition_idset(s::PnmlNetKeys) = s.transition_set
arc_idset(s::PnmlNetKeys) = s.arc_set
reftransition_idset(s::PnmlNetKeys) = s.reftransition_set
refplace_idset(s::PnmlNetKeys) = s.refplace_set

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
    for (tag, idset) in (("pages", page_idset),
                        ("places", place_idset),
                        ("transitions", transition_idset),
                        ("arcs", arc_idset),
                        ("refplaces", refplace_idset),
                        ("refTransitions", reftransition_idset))
        print(io, indent(io), length(idset(pns)), " ", tag, ": ")
        iio = inc_indent(io)
        for (i,k) in enumerate(values(idset(pns)))
            print(io, repr(k), ", ")
            if (i < length(idset(pns))) && (i % 25 == 0)
                print(iio, '\n', indent(iio))
            end
        end
        println(io)
    end
end
