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

    declaration::Declaration = Declaration() # Label with `DeclDict`, `Text` `Graphics`, `ToolInfo`.
    # Zero or more `Declarations` used to populate ddict::DeclDict field.
    # Yes, The ISO 15909-2 Standard uses `Declarations` inside `Declaration`.

    namelabel::Maybe{Name} = nothing
    # no graphics for net
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing
    extralabels::Vector{PnmlLabel} = PnmlLabel[] # empty by default
    idregistry::PnmlIDRegistry = PnmlIDRegistry()
end

# Constructor for use in test scaffolding.
PnmlNet(t::PnmlType, x::Symbol) = PnmlNet(; type=t, id=x, pagedict=OrderedDict{Symbol, Page{typeof(t)}}())

pntd(net::PnmlNet) = net.type
nettype(net::PnmlNet) = typeof(net.type)

pid(net::PnmlNet) = net.id

"Return PnmlIDRegistry of a PnmlNet."
registry_of(net::PnmlNet) = net.idregistry
decldict(net::PnmlNet) = decldict(net.declaration)

# `pagedict` is all pages in `net`, `page_idset` only for direct pages of net.
pagedict(net::PnmlNet) = net.pagedict # Will be ordered.
page_idset(net::PnmlNet) = net.page_set

netdata(net::PnmlNet) = net.netdata

placedict(net::PnmlNet)         = placedict(netdata(net))
transitiondict(net::PnmlNet)    = transitiondict(netdata(net))
arcdict(net::PnmlNet)           = arcdict(netdata(net))
refplacedict(net::PnmlNet)      = refplacedict(netdata(net))
reftransitiondict(net::PnmlNet) = reftransitiondict(netdata(net))

netsets(net::PnmlNet)  = throw(ArgumentError("PnmlNet $(pid(net)) does not have a PnmlKeySet, did you mean `netdata`?"))

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

has_labels(net::PnmlNet) = !isnothing(net.extralabels)
labels(net::PnmlNet)     = net.extralabels # Vectors are iteratable.

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

# Iterate IDs of arcs that have given source or target.values(arcdict((net)))
all_arcs(net::PnmlNet, id::Symbol) =
    Iterators.map(pid, Iterators.filter(a -> (source(a) === id || target(a) === id), values(arcdict(net))))
src_arcs(net::PnmlNet, id::Symbol) =
    Iterators.map(pid, Iterators.filter(a -> (source(a) === id), values(arcdict(net))))
tgt_arcs(net::PnmlNet, id::Symbol) =
    Iterators.map(pid, Iterators.filter(a -> (target(a) === id), values(arcdict(net))))

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
function verify(net::PnmlNet;
                verbose::Bool = CONFIG[].verbose)
    #verbose && println("verify PnmlNet $(pid(net))"); flush(stdout)
    errors = String[]

    verify!(errors, net; verbose, idreg=registry_of(net))

    isempty(errors) ||
        error("verify(net) error(s): ", join(errors, ",\n "))
    return true
end

function verify!(errors, net::PnmlNet;
                verbose::Bool = CONFIG[].verbose, idreg::PnmlIDRegistry)
    # Are the things with PNML IDs in the PnmlIDRegistry?
    !isregistered(idreg, pid(net)) &&
         push!(errors, string("net id ", repr(pid(net)), " not registered")::String)

    for pg in pages(net)
        !isregistered(idreg, pid(pg)) &&
        push!(errors, string("pages() page id ", repr(pid(pg)), " not registered")::String)
    end
    for pg in allpages(net)
        !isregistered(idreg, pid(pg)) &&
            push!(errors, string("allpages() page id ", repr(pid(pg)), " not registered")::String)
    end
    for pl in places(net)
        !isregistered(idreg, pid(pl)) &&
            push!(errors, string("place id ", repr(pid(pl)), " not registered")::String)
    end
    for tr in transitions(net)
        !isregistered(idreg, pid(tr)) &&
            push!(errors, string("transition id ", repr(pid(tr)), " not registered")::String)
    end
    for ar in arcs(net)
        !isregistered(idreg, pid(ar)) &&
            push!(errors, string("arc id ", repr(pid(ar)), " not registered")::String)
    end
    for rp in refplaces(net)
        !isregistered(idreg, pid(rp)) &&
            push!(errors, string("refPlace id ", repr(pid(rp)), " not registered")::String)
    end
    for rt in reftransitions(net)
        !isregistered(idreg, pid(rt)) &&
            push!(errors, string("refTranition id ", repr(pid(rt)), " not registered")::String)
    end

    # Call net object's verify method.
    for pg in allpages(net)
        verify!(errors, pg; verbose, idreg) #TODO collect diagnostics, or die?
    end
    # places(net), transitions(net), arcs(net)
    # declarations(net)
    # toolinfos(net)
    # labels(net)
    return errors
end

#------------------------------------------------------------------------------
function Base.summary(net::PnmlNet)
    string(typeof(net), " id ", pid(net),
            " name '", has_name(net) ? name(net) : "", ", ",
            " type ", nettype(net), ", ",
            npages(net), " pages, ",
            ndeclarations(net), " declarations, ",
            has_tools(net) ? length(toolinfos(net)) : 0, " toolinfos, ",
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

#------------------------------------------------------------------------------
# Construct Types
#------------------------------------------------------------------------------

page_type(::Type{T}) where {T<:PnmlType} = Page{T}

place_type(::Type{T}) where {T<:PnmlType}         = Place
transition_type(::Type{T}) where {T<:PnmlType}    = Transition
arc_type(::Type{T}) where {T<:PnmlType}           = Arc
refplace_type(::Type{T}) where {T<:PnmlType}      = RefPlace
reftransition_type(::Type{T}) where {T<:PnmlType} = RefTransition

page_type(::PnmlNet{T}) where {T<:PnmlType} = Page{T}

place_type(::PnmlNet{T}) where {T<:PnmlType}         = Place
transition_type(::PnmlNet{T}) where {T<:PnmlType}    = Transition
arc_type(::PnmlNet{T}) where {T<:PnmlType}           = Arc
refplace_type(::PnmlNet{T}) where {T<:PnmlType}      = RefPlace
reftransition_type(::PnmlNet{T}) where {T<:PnmlType} = RefTransition
