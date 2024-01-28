"""
$(TYPEDEF)
$(TYPEDFIELDS)

One Petri Net of a PNML model.
"""
@kwdef struct PnmlNet{PNTD<:PnmlType, P, T, A, RP, RT}
    type::PNTD
    id::Symbol
    pagedict::OrderedDict{Symbol, Page{PNTD, P, T, A, RP, RT}} # Shared by pages, holds all pages.
    netdata::PnmlNetData{PNTD, P, T, A, RP, RT} # Shared by pages, holds all places, transitions, arcs, refs
    page_set::OrderedSet{Symbol} # Keys of pages in pagedict owned by this net. Top-level of a tree with PnmlNetKeys.
    declaration::Declaration
    namelabel::Maybe{Name}
    tools::Vector{ToolInfo}
    labels::Vector{PnmlLabel}
    idregistry::PnmlIDRegistry # Shared by all nets in a pnml model.
end

#nettype(::PnmlNet{T}) where {T <: PnmlType} = T
PnmlTypeDefs.pnmltype(net::PnmlNet) = net.type
nettype(net::PnmlNet) = typeof(pnmltype(net))

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

place_type(::Type{T}) where {T<:PnmlType} = Place{T,
                                                  marking_type(T),
                                                  SortType}
transition_type(::Type{T}) where {T<:PnmlType}    = Transition{T, condition_type(T)}
arc_type(::Type{T}) where {T<:PnmlType}           = Arc{T, inscription_type(T)}
refplace_type(::Type{T}) where {T<:PnmlType}      = RefPlace{T}
reftransition_type(::Type{T}) where {T<:PnmlType} = RefTransition{T}

page_type(::PnmlNet{T}) where {T<:PnmlType} = Page{T,
                                                   place_type(T),
                                                   transition_type(T),
                                                   arc_type(T),
                                                   refplace_type(T),
                                                   reftransition_type(T)}

place_type(::PnmlNet{T}) where {T<:PnmlType} = Place{T,
                                                     marking_type(T),
                                                     SortType}
transition_type(::PnmlNet{T}) where {T<:PnmlType}    = Transition{T, condition_type(T)}
arc_type(::PnmlNet{T}) where {T<:PnmlType}           = Arc{T, inscription_type(T)}
refplace_type(::PnmlNet{T}) where {T<:PnmlType}      = RefPlace{T}
reftransition_type(::PnmlNet{T}) where {T<:PnmlType} = RefTransition{T}

condition_type(net::PnmlNet)       = condition_type(nettype(net))
condition_value_type(net::PnmlNet) = condition_value_type(nettype(net))

inscription_type(net::PnmlNet)       = inscription_type(nettype(net))
inscription_value_type(net::PnmlNet) = inscription_value_type(nettype(net))
rate_value_type(net::PnmlNet)        = rate_value_type(nettype(net))

marking_type(net::PnmlNet)       = marking_type(nettype(net))
marking_value_type(net::PnmlNet) = marking_value_type(nettype(net))

#--------------------------------------
pid(net::PnmlNet)  = net.id
idregistry(net::PnmlNet) = net.idregistry

# `pagedict` is all pages in `net`, `page_idset` only for direct pages of net.
pagedict(n::PnmlNet) = n.pagedict
page_idset(n::PnmlNet)  = n.page_set

netdata(n::PnmlNet)  = n.netdata
netsets(n::PnmlNet)  = (throw ∘ ArgumentError)("PnmlNet $(pid(n)) does not have a PnmlKeySet, did you mean `netdata`?")

place_idset(n::PnmlNet)         = keys(placedict(n))
transition_idset(n::PnmlNet)    = keys(transitiondict(n))
arc_idset(n::PnmlNet)           = keys(arcdict(n))
reftransition_idset(n::PnmlNet) = keys(reftransitiondict(n))
refplace_idset(n::PnmlNet)      = keys(refplacedict(n))

npage(n::PnmlNet)          = length(pagedict(n))
nplace(n::PnmlNet)         = nplace(netdata(n))
ntransition(n::PnmlNet)    = ntransition(netdata(n))
narc(n::PnmlNet)           = narc(netdata(n))
nrefplace(n::PnmlNet)      = nrefplace(netdata(n))
nreftransition(n::PnmlNet) = nreftransition(netdata(n))

"""
    allpages(net::PnmlNet|dict::OrderedDict) -> Iterator

Return iterator over all pages in the net. Maintains insertion order.
"""
allpages(net::PnmlNet) = allpages(pagedict(net))
allpages(pd::OrderedDict) = values(pd)

"Iterator of `Pages` directly owned by `net`."
pages(net::PnmlNet) = Iterators.filter(v -> in(pid(v), page_idset(net)), allpages(net))

"Usually the only interesting page."
firstpage(net::PnmlNet)    = (first ∘ values ∘ pagedict)(net)

declarations(net::PnmlNet) = declarations(net.declaration) # Forward to the collection object.

tools(net::PnmlNet)     = net.tools

has_labels(net::PnmlNet) = true
labels(net::PnmlNet)     = net.labels

has_name(net::PnmlNet) = hasproperty(net, :namelabel) && !isnothing(net.namelabel)
name(net::PnmlNet)     = has_name(net) ? text(net.namelabel) : ""

places(net::PnmlNet)         = values(placedict(net))
transitions(net::PnmlNet)    = values(transitiondict(net))
arcs(net::PnmlNet)           = values(arcdict(net))
refplaces(net::PnmlNet)      = values(refplacedict(net))
reftransitions(net::PnmlNet) = values(reftransitiondict(net))

place(net::PnmlNet, id::Symbol)        = placedict(net)[id]
has_place(net::PnmlNet, id::Symbol)    = haskey(placedict(net), id)

initial_marking(net::PnmlNet, placeid::Symbol) = initial_marking(place(net, placeid))

transition(net::PnmlNet, id::Symbol)      = transitiondict(net)[id]
has_transition(net::PnmlNet, id::Symbol)  = haskey(transitiondict(net), id)

condition(net::PnmlNet, trans_id::Symbol) = condition(transition(net, trans_id))

arc(net::PnmlNet, id::Symbol)      = arcdict(net)[id]
has_arc(net::PnmlNet, id::Symbol)  = haskey(arcdict(net), id)


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

inscription(net::PnmlNet, arc_id::Symbol) = inscription(arcdict(net)[arc_id])

has_refplace(net::PnmlNet, id::Symbol)      = haskey(refplacedict(net), id)
refplace(net::PnmlNet, id::Symbol)          = refplacedict(net)[id]
has_reftransition(net::PnmlNet, id::Symbol) = haskey(reftransitiondict(net), id)
reftransition(net::PnmlNet, id::Symbol)     = reftransitiondict(net)[id]

# Some helpers for metagraph. Will be useful in validating.
# pnml id symbol converted to/from vertex code.
vertex_codes(n::PnmlNet)  = Dict(s=>i for (i,s) in enumerate(union(place_idset(n), transition_idset(n))))
vertex_labels(n::PnmlNet) = Dict(i=>s for (i,s) in enumerate(union(place_idset(n), transition_idset(n))))

vertexdata(net::PnmlNet) = begin
    vcode = vertex_codes(net)
    vdata = Dict{Symbol, Tuple{Int, Union{Place, Transition}}}()
    for p in places(net)
        vdata[pid(p)] = (vcode[pid(p)], p)
    end
    for t in transitions(net)
        vdata[pid(t)] = (vcode[pid(t)], t)
    end
    return vdata
    # Dict(pid(x) => (vcode[pid(x)], x) for x in Iterators.flatten(places(n), transitions(n)))
end

"""
"""
function verify(net::PnmlNet; verbose::Bool = CONFIG.verbose)
    verbose && println("verify PnmlNet")
    errors = String[]

    !isregistered(idregistry(net), pid(net)) && 
        push!(errors, string("net id ", repr(pid(net)), " not registered in \n", repr(idregistry(net))))


    isempty(errors) ||
        error("verify(net) errors: ", join(errors, ",\n "))
    return true
end


function Base.summary(net::PnmlNet)
    string(typeof(net), " id ", pid(net),
            " name '", has_name(net) ? name(net) : "", ", ",
            " type ", nettype(net), ", ",
            length(pagedict(net)), " pages ",
            length(declarations(net)), " declarations",
            length(tools(net)), " tools, ",
            length(labels(net)), " labels")
end

# No indent here.
function Base.show(io::IO, net::PnmlNet)
    print(io, indent(io), nameof(typeof(net)), 
            "(", repr(pid(net)), ", ",repr(name(net)), ", ", repr(nettype(net)), ", ")
    iio = inc_indent(io)
    println(io)
    print(io, "Pages = ", repr(page_idset(net)))
    for page in values(pagedict(net))
        print(iio, '\n', indent(iio)); show(iio, page)
    end
    println(io)
    print(io, "Declarations[")
    for (i,decl) in enumerate(declarations(net))
        print(iio, "\n", indent(iio)); show(iio, decl)
        i < length(declarations(net)) && print(iio, ", ")
    end
    println(io, "], ")
    show(io, tools(net)); println(io, ", ")
    show(io, labels(net)); println(io, ", ")
    show(io, netdata(net)); println(io, ")")

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

    println(io, "Reference Transitions")
    map(reftransitions(net)) do rt
        show(io, rt); println(io)
    end

end
