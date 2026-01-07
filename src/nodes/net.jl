"""
$(TYPEDEF)
$(TYPEDFIELDS)

One Petri Net of a PNML model.
"""
@kwdef mutable struct PnmlNet{PNTD<:PnmlType} <: AbstractPnmlNet
    type::PNTD
    id::Symbol
    pagedict::OrderedDict{Symbol, Page{PNTD}} # Shared by pages, holds all pages.
    netdata::PnmlNetData = PnmlNetData() # Shared by pages, holds all places, transitions, arcs, refs

    # Note: `PnmlNet` only has `page_set` not `netsets` as it only contains pages.
    # All PNML net Objects are attached to a `Page`. And there must be one `Page`.
    page_set::OrderedSet{Symbol} = OrderedSet{Symbol}()# REFID keys of pages in pagedict owned by this net.

    declaration::Declaration # Label with `DeclDict`, `Text` `Graphics`, `ToolInfo`.
    # Zero or more `Declarations` used to populate ddict::DeclDict field.
    # Yes, The ISO 15909-2 Standard uses `Declarations` inside `Declaration`.

    namelabel::Maybe{Name} = nothing
    # no graphics for net
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing
    extralabels::LittleDict{Symbol,Any} = LittleDict{Symbol,Any}() # empty by default
    idregistry::IDRegistry
end

# Constructor for use in test scaffolding.
PnmlNet(type::PnmlType, id::Symbol; declaration=Declaration(; ddict=DeclDict())) =
    PnmlNet(; type, id, declaration,
            pagedict=OrderedDict{Symbol, Page{typeof(type)}}(),
             idregistry=IDRegistry())

pntd(net::PnmlNet) = net.type
nettype(net::PnmlNet) = typeof(net.type)

pid(net::PnmlNet) = net.id

"Return IDRegistry of a PnmlNet."
registry_of(net::PnmlNet) = net.idregistry
decldict(net::PnmlNet) = decldict(net.declaration)

# `pagedict` is all pages in `net`, `page_idset` only for direct pages of net.
pagedict(net::PnmlNet) = net.pagedict # Will be ordered.
page_idset(net::PnmlNet) = net.page_set # Indices into `pagedict` directly owned by net.

netdata(net::PnmlNet) = net.netdata
netsets(net::PnmlNet) = throw(ArgumentError("PnmlNet $(pid(net)) does not have a PnmlKeySet, did you mean `netdata`?"))

placedict(net::PnmlNet)         = placedict(netdata(net))
transitiondict(net::PnmlNet)    = transitiondict(netdata(net))
arcdict(net::PnmlNet)           = arcdict(netdata(net))
refplacedict(net::PnmlNet)      = refplacedict(netdata(net))
reftransitiondict(net::PnmlNet) = reftransitiondict(netdata(net))

#"Return iterator over keys of a dictionary" #! verify same as PnmlKeySet for flattened page
place_idset(net::PnmlNet)         = keys(placedict(net))
transition_idset(net::PnmlNet)    = keys(transitiondict(net))
arc_idset(net::PnmlNet)           = keys(arcdict(net))
refplace_idset(net::PnmlNet)      = keys(refplacedict(net))
reftransition_idset(net::PnmlNet) = keys(reftransitiondict(net))

npages(net::PnmlNet)          = length(pagedict(net))
nplaces(net::PnmlNet)         = length(placedict(net))
ntransitions(net::PnmlNet)    = length(transitiondict(net))
narcs(net::PnmlNet)           = length(arcdict(net))
nrefplaces(net::PnmlNet)      = length(refplacedict(net))
nreftransitions(net::PnmlNet) = length(reftransitiondict(net))
ndeclarations(net::PnmlNet)   = length(decldict(net))

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

has_tools(net::PnmlNet) = !isnothing(net.toolspecinfos)
toolinfos(net::PnmlNet)     = net.toolspecinfos

function name(net::PnmlNet)
    if hasproperty(net, :namelabel) && !isnothing(net.namelabel)
        text(net.namelabel)
    else
        ""
    end
end

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
Return `Arc` from 's' to 't' or `nothing`.
Useful for graphs where arcs are represented by a tuple or pair (source,target).
"""
arc(net, s::Symbol, t::Symbol) = begin
    x = Iterators.filter(a -> source(a) === s && target(a) === t, arcs(net))
    isempty(x) ? nothing : first(x)
end

# Iterate IDs of arcs that have given source or target.values(arcdict((net)))
all_arcs(net::PnmlNet, id::Symbol) =
    Iterators.map(pid,
        Iterators.filter(a -> (source(a) === id || target(a) === id), values(arcdict(net))))
src_arcs(net::PnmlNet, id::Symbol) =
    Iterators.map(pid,
        Iterators.filter(a -> (source(a) === id), values(arcdict(net))))
tgt_arcs(net::PnmlNet, id::Symbol) =
    Iterators.map(pid,
        Iterators.filter(a -> (target(a) === id), values(arcdict(net))))

"Forward `inscription` to `arcdict`"
inscription(net::PnmlNet, arc_id::Symbol) = inscription(arcdict((net))[arc_id])

has_refplace(net::PnmlNet, id::Symbol)      = haskey(refplacedict((net)), id)
refplace(net::PnmlNet, id::Symbol)          = refplacedict((net))[id]
has_reftransition(net::PnmlNet, id::Symbol) = haskey(reftransitiondict((net)), id)
reftransition(net::PnmlNet, id::Symbol)     = reftransitiondict((net))[id]


#------------------------------------------------------------------------------
"""
Error if any diagnostic messages are collected. Especially intended to detect semantc error.
"""
function verify(net::PnmlNet; verbose::Bool)
    verbose &&
        println("## verify $(typeof(net)) $(pid(net))"); flush(stdout)
    errors = String[]
    verify!(errors, net, verbose, registry_of(net))
    isempty(errors) || error("verify(net) $(pid(net)) error(s):\n ", join(errors, ",\n "))
    return true
end

function verify!(errors::Vector{String}, net::PnmlNet, verbose::Bool, idreg::IDRegistry)
    # pagedict
    # netdata
    # page_set
    # toolspecifics
    # extralabels

    # Are the things with PNML IDs in the IDRegistry?
    verify_id!(errors, "net id", (net,), idreg)
    verify_id!(errors, "pages id", pages(net), idreg)
    verify_id!(errors, "allpages id", allpages(net), idreg)
    verify_id!(errors, "places id", places(net), idreg)
    verify_id!(errors, "transition id", transitions(net), idreg)
    verify_id!(errors, "arcs id", arcs(net), idreg)
    verify_id!(errors, "refplaces id", refplaces(net), idreg)
    verify_id!(errors, "reftransitions id", reftransitions(net), idreg)

    verify!(errors, decldict(net), verbose, idreg)

    verify!(errors, net.declaration, verbose, idreg)

    # Call net object's verify method.
    foreach(x -> verify!(errors, x, verbose, idreg), allpages(net))
    foreach(x -> verify!(errors, x, verbose, idreg), places(net))
    foreach(x -> verify!(errors, x, verbose, idreg), transitions(net))
    foreach(x -> verify!(errors, x, verbose, idreg), arcs(net))
    foreach(x -> verify!(errors, x, verbose, idreg), refplaces(net))
    foreach(x -> verify!(errors, x, verbose, idreg), reftransitions(net))

    !isnothing(toolinfos(net)) &&
        foreach(x -> verify!(errors, x, verbose, idreg), toolinfos(net))
    # foreach(x -> verify!(errors, x, verbose, idreg), extralabels(net))

    if npages(net) == 1
        @assert npages(net) == length(page_idset(net))
        nrefplaces(net) == 0 ||
            push!(errors, "npages==1 && refplacedict not empty")
        isempty(refplace_idset(net)) ||
            push!(errors, "npages==1 && refplace_idset not empty")
        nreftransitions(net) == 0 ||
            push!(errors, "npages==1 && reftransitiondict not empty")
        isempty(reftransition_idset(net)) ||
            push!(errors, "npages==1 && reftransition_idset not empty")
    end
    return errors
end

"""
    verify_id!(errors::Vector{String}, str, iterable, idreg::IDRegistry) -> Vector{String}

Iterate over `iterable` testing that `pid` is registered in `idreg`.
`str` used in message appended to `errors` vector.
"""
function verify_id!(errors::Vector{String}, str::AbstractString, iterable, idreg::IDRegistry)
    for x in iterable
        !isregistered(idreg, pid(x)) &&
            push!(errors, string(str, " ", repr(pid(x)), " not registered")::String)
    end
end


#------------------------------------------------------------------------------
function Base.summary(net::PnmlNet)
    string(typeof(net), " id ", repr(pid(net)),
            " name ", repr(name(net)), ", ",
            " type ", nettype(net), ", ",
            npages(net), " pages, ",
            ndeclarations(net), " declarations, ",
            has_tools(net) ? length(toolinfos(net)) : 0, " toolinfos, ")::String
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
    println(io, "Declarations = ", repr(decldict(net)))
    show(io, toolinfos(net)); println(io, ", ")
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
