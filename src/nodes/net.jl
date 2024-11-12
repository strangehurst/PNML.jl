"""
$(TYPEDEF)
$(TYPEDFIELDS)

One Petri Net of a PNML model.
"""
@kwdef mutable struct PnmlNet{PNTD<:PnmlType, P, T, A, RP, RT}
    type::PNTD
    id::Symbol
    pagedict::OrderedDict{Symbol, Page{PNTD, P, T, A, RP, RT}} # Shared by pages, holds all pages.
    netdata::PnmlNetData{PNTD} # !, P, T, A, RP, RT} # Shared by pages, holds all places, transitions, arcs, refs
    page_set::Set{Symbol} # Keys of pages in pagedict owned by this net. Top-level of a tree with PnmlNetKeys in Pages.
    declaration::Declaration
    namelabel::Maybe{Name}
    tools::Maybe{Vector{ToolInfo}}
    labels::Maybe{Vector{PnmlLabel}}
    idregistry::PnmlIDRegistry
end

pntd(net::PnmlNet) = net.type
nettype(net::PnmlNet) = typeof(net.type)

pid(net::PnmlNet)  = net.id

# `pagedict` is all pages in `net`, `page_idset` only for direct pages of net.
pagedict(n::PnmlNet) = n.pagedict
page_idset(n::PnmlNet)  = n.page_set

netdata(n::PnmlNet)  = n.netdata

placedict(n::PnmlNet)         = placedict(netdata(n))
transitiondict(n::PnmlNet)    = transitiondict(netdata(n))
arcdict(n::PnmlNet)           = arcdict(netdata(n))
refplacedict(n::PnmlNet)      = refplacedict(netdata(n))
reftransitiondict(n::PnmlNet) = reftransitiondict(netdata(n))

netsets(n::PnmlNet)  = throw(ArgumentError("PnmlNet $(pid(n)) does not have a PnmlKeySet, did you mean `netdata`?"))
"Return iterator over keys of a dictionary"
place_idset(n::PnmlNet)         = keys(placedict(n))
transition_idset(n::PnmlNet)    = keys(transitiondict(n))
arc_idset(n::PnmlNet)           = keys(arcdict(n))
refplace_idset(n::PnmlNet)      = keys(refplacedict(n))
reftransition_idset(n::PnmlNet) = keys(reftransitiondict(n))

npages(n::PnmlNet)          = length(pagedict(n))
nplaces(n::PnmlNet)         = length(placedict(n))
ntransitions(n::PnmlNet)    = length(transitiondict(n))
narcs(n::PnmlNet)           = length(arcdict(n))
nrefplaces(n::PnmlNet)      = length(refplacedict(n))
nreftransitions(n::PnmlNet) = length(reftransitiondict(n))

"""
    allpages(net::PnmlNet|dict::OrderedDict) -> Iterator

Return iterator over all pages in the net. Maintains insertion order.
"""
allpages(net::PnmlNet) = allpages(pagedict(net))
allpages(pd::OrderedDict) = values(pd)

"Iterator of `Pages` directly owned by `net`."
pages(net::PnmlNet) = Iterators.filter(v -> in(pid(v), page_idset(net)), allpages(net))

"Usually the only interesting page."
firstpage(net::PnmlNet)    = first(values(pagedict(net)))

declarations(net::PnmlNet) = declarations(net.declaration) # Forward to the collection object.

has_tools(net::PnmlNet) = !isnothing(net.tools)
tools(net::PnmlNet)     = net.tools

has_labels(net::PnmlNet) = !isnothing(net.labels)
labels(net::PnmlNet)     = net.labels

has_name(net::PnmlNet) = hasproperty(net, :namelabel) && !isnothing(net.namelabel)
name(net::PnmlNet)     = has_name(net) ? text(net.namelabel) : ""

places(net::PnmlNet)         = values(placedict((net)))
transitions(net::PnmlNet)    = values(transitiondict((net)))
arcs(net::PnmlNet)           = values(arcdict((net)))
refplaces(net::PnmlNet)      = values(refplacedict((net)))
reftransitions(net::PnmlNet) = values(reftransitiondict((net)))

place(net::PnmlNet, id::Symbol)        = placedict((net))[id]
has_place(net::PnmlNet, id::Symbol)    = haskey(placedict((net)), id)

initial_marking(net::PnmlNet, placeid::Symbol) = initial_marking(place(net, placeid))

transition(net::PnmlNet, id::Symbol)      = transitiondict((net))[id]
has_transition(net::PnmlNet, id::Symbol)  = haskey(transitiondict((net)), id)

condition(net::PnmlNet, trans_id::Symbol) = condition(transition(net, trans_id))

arc(net::PnmlNet, id::Symbol)      = arcdict((net))[id]
has_arc(net::PnmlNet, id::Symbol)  = haskey(arcdict((net)), id)

"""
Return `Arc` from 's' to 't' or `nothing`. Useful for graphs where arcs are represented by a tuple(source,target).
"""
arc(net, s::Symbol, t::Symbol) = begin
    x = Iterators.filter(a -> source(a) === s && target(a) === t, arcs(net))
    isempty(x) ? nothing : first(x)
end

all_arcs(net::PnmlNet, id::Symbol) = Iterators.filter(a -> source(a) === id || target(a) === id, arcs(net))
src_arcs(net::PnmlNet, id::Symbol) = Iterators.filter(a -> source(a) === id, arcs(net))
tgt_arcs(net::PnmlNet, id::Symbol) = Iterators.filter(a -> target(a) === id, arcs(net))

"Lookup inscription in `arcdict`"
inscription(net::PnmlNet, arc_id::Symbol) = inscription(arcdict((net))[arc_id])

has_refplace(net::PnmlNet, id::Symbol)      = haskey(refplacedict((net)), id)
refplace(net::PnmlNet, id::Symbol)          = refplacedict((net))[id]
has_reftransition(net::PnmlNet, id::Symbol) = haskey(reftransitiondict((net)), id)
reftransition(net::PnmlNet, id::Symbol)     = reftransitiondict((net))[id]

"""
Error if any diagnostic messages are collected. Especially intended to detect semantc error.
"""
function verify(net::PnmlNet; verbose::Bool = CONFIG[].verbose)
    verbose && println("verify PnmlNet $(pid(net))"); flush(stdout)
    errors = String[]

    verify!(errors, net; verbose)

    isempty(errors) ||
        error("verify(net) error(s): ", join(errors, ",\n "))
    return true
end

function verify!(errors, net::PnmlNet; verbose::Bool = CONFIG[].verbose)
    # Are the things with PNML IDs in the PnmlIDRegistry?
    !isregistered(idregistry[], pid(net)) &&
        push!(errors, string("net id ", repr(pid(net)), " not registered")::String)

    for pg in pages(net)
        !isregistered(idregistry[], pid(pg)) &&
        push!(errors, string("pages() page id ", repr(pid(pg)), " not registered")::String)
    end
    for pg in allpages(net)
        !isregistered(idregistry[], pid(pg)) &&
            push!(errors, string("allpages() page id ", repr(pid(pg)), " not registered")::String)
    end
    for pl in places(net)
        !isregistered(idregistry[], pid(pl)) &&
            push!(errors, string("place id ", repr(pid(pl)), " not registered")::String)
    end
    for tr in transitions(net)
        !isregistered(idregistry[], pid(tr)) &&
            push!(errors, string("transition id ", repr(pid(tr)), " not registered")::String)
    end
    for ar in arcs(net)
        !isregistered(idregistry[], pid(ar)) &&
            push!(errors, string("arc id ", repr(pid(ar)), " not registered")::String)
    end
    for rp in refplaces(net)
        !isregistered(idregistry[], pid(rp)) &&
            push!(errors, string("refPlace id ", repr(pid(rp)), " not registered")::String)
    end
    for rt in reftransitions(net)
        !isregistered(idregistry[], pid(rt)) &&
            push!(errors, string("refTranition id ", repr(pid(rt)), " not registered")::String)
    end

    # Call net object's verify method.
    for pg in allpages(net)
        verify!(errors, pg; verbose) #TODO collect diagnostics, or die?
    end
    # places(net), transitions(net), arcs(net)
    # declarations(net)
    # tools(net)
    # labels(net)
    return nothing
end

function Base.summary(net::PnmlNet)
    string(typeof(net), " id ", pid(net),
            " name '", has_name(net) ? name(net) : "", ", ",
            " type ", nettype(net), ", ",
            npages(net), " pages ",
            ndeclarations(net), " declarations",
            has_tools(net) ? length(tools(net)) : 0, " tools, ",
            has_labels(net) ? length(labels(net)) : 0, " labels")::String
end

# No indent here.
function Base.show(io::IO, net::PnmlNet)
    print(io, indent(io), nameof(typeof(net)), "(", )
    print(repr(pid(net)), ", ")
    print(repr(name(net)), ", ")
    print(repr(nettype(net)), ", ")
    iio = inc_indent(io)
    println(io)
    print(io, "Pages = ", repr(page_idset(net)))
    for page in values(pagedict(net))
        print(iio, '\n', indent(iio)); show(iio, page)
    end
    println(io)
    print(io, "Declarations = ", repr(declarations(net)))
    show(io, tools(net)); println(io, ", ")
    show(io, labels(net)); println(io, ", ")
    show(io, nettype(net)); println(io, ")")

    println(io, "Arcs:")
    map(arcs(net)) do a
        show(io, a); println(io)
    end
    println(io, "Places:")
    map(places(net)) do p
        show(io, p); println(io)
    end
    println(io, "Transitions:")
    map(transitions(net)) do t
        show(io, t); println(io)
    end

    println(io, "Reference Places:")
    map(refplaces(net)) do rp
        show(io, rp); println(io)
    end

    println(io, "Reference Transitions:")
    map(reftransitions(net)) do rt
        show(io, rt); println(io)
    end

end

pnmlnet_type(::Type{T}) where {T<:PnmlType} = PnmlNet{T,
                                                      place_type(T),
                                                      transition_type(T),
                                                      arc_type(T),
                                                      refplace_type(T),
                                                      reftransition_type(T)}

page_type(::Type{T}) where {T<:PnmlType} = Page{T,
                                                place_type(T),
                                                transition_type(T),
                                                arc_type(T),
                                                refplace_type(T),
                                                reftransition_type(T)}

place_type(::Type{T}) where {T<:PnmlType}         = Place{T, marking_type(T)}
transition_type(::Type{T}) where {T<:PnmlType}    = Transition{T, condition_type(T)}
arc_type(::Type{T}) where {T<:PnmlType}           = Arc{inscription_type(T)}
refplace_type(::Type{T}) where {T<:PnmlType}      = RefPlace
reftransition_type(::Type{T}) where {T<:PnmlType} = RefTransition

page_type(::PnmlNet{T}) where {T<:PnmlType} = Page{T,
                                                   place_type(T),
                                                   transition_type(T),
                                                   arc_type(T),
                                                   refplace_type(T),
                                                   reftransition_type(T)}

place_type(::PnmlNet{T}) where {T<:PnmlType}         = Place{T, marking_type(T)}
transition_type(::PnmlNet{T}) where {T<:PnmlType}    = Transition{T, condition_type(T)}
arc_type(::PnmlNet{T}) where {T<:PnmlType}           = Arc{inscription_type(T)}
refplace_type(::PnmlNet{T}) where {T<:PnmlType}      = RefPlace
reftransition_type(::PnmlNet{T}) where {T<:PnmlType} = RefTransition

condition_type(net::PnmlNet)       = condition_type(nettype(net))
condition_value_type(net::PnmlNet) = condition_value_type(nettype(net))

inscription_type(net::PnmlNet)       = inscription_type(nettype(net))
inscription_value_type(net::PnmlNet) = inscription_value_type(nettype(net))
rate_value_type(net::PnmlNet)        = rate_value_type(nettype(net))

marking_type(net::PnmlNet)       = marking_type(nettype(net))
marking_value_type(net::PnmlNet) = marking_value_type(nettype(net))
