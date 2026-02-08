"""
$(TYPEDEF)

One Petri Net of a PNML model.

$(TYPEDFIELDS)

"""
@kwdef mutable struct PnmlNet{PNTD<:PnmlType} <: AbstractPnmlNet
    "The meta-model type this net implements."
    const type::PNTD
    # PNML ID needed here for multiple nets of same `type` in a `<pnml>` model.
    const id::Symbol
    # Ensure that each PNML ID in a net is unique using a registry.
    idregistry::IDRegistry
    # Holds all pages. Shared by pages that may have sub-pages.
    # All PNML net objects are attached to a `Page`. And there must be at least one `Page`.
    pagedict::OrderedDict{Symbol, Page{PNTD,<:AbstractPnmlNet}} #todo
    # Shared by pages, holds all places, transitions, arcs, refs
    netdata::PnmlNetData = PnmlNetData()
    # Keys of pages in `pagedict` owned by this net.
    # Use only `page_idset` not full `netsets` collection as net only contains pages.
    page_idset::OrderedSet{Symbol} = OrderedSet{Symbol}()
    # Declarations dictionarys filled with built-ins & when parsing `declaration`.
    # We use the declarations toolkit for non-high-level nets,
    # and assume a minimum level of function for high-level nets.
    # Declarations present in the input file will overwrite these. Particulary '<dot>'.
    ddict::DeclDict = DeclDict() # empty dictionarys
    # PNML Label with `Text` `Graphics`, `ToolInfo` and zero or more `Declarations`.
    # Yes, The ISO 15909-2 Standard uses `Declarations` inside `Declaration`.
    # Used to populate `ddict`.
    declaration::Maybe{Declaration} = nothing
    # PNML Label with `Text` `Graphics`, `ToolInfo`.
    namelabel::Maybe{Name} = nothing
    # Zero or more `<toolspecific>` may be attched to net.
    toolspecinfos::Vector{ToolInfo} = ToolInfo[]
    # Zero or more PNML Labels may be attched to net. Extends meta-models of ISO 15909.
    extralabels::LittleDict{Symbol,Any} = LittleDict{Symbol,Any}()
    # Map xml tag symbol to parser callable for built-in labels and extension labels.
    labelparser::LittleDict{Symbol, Base.Callable} = LittleDict{Symbol, Base.Callable}()
    """
        Collection that associates a tool name & version with a callable parser.
        The parser turns `<toolspecific name="" version="">` into `ToolInfo` objects.
    """
    toolparser::LittleDict{Pair{String,String}, Base.Callable} = LittleDict{Pair{String,String}, Base.Callable}()
end

"Create empty net with builtins installed for use in test scaffolding."
function make_net(type::PnmlType, id=:make_net,)
    net = PnmlNet(; type, id,
                    idregistry=IDRegistry(),
                    pagedict=OrderedDict{Symbol, Page{typeof(type)}}(),
                    declaration=Declaration(; ddict=DeclDict()))
    PNML.fill_builtin_sorts!(net)
    PNML.fill_builtin_labelparsers!(net)
    return net
end

pntd(net::PnmlNet) = net.type
nettype(net::PnmlNet) = typeof(net.type)

pid(net::PnmlNet) = net.id

"Return IDRegistry of a PnmlNet."
registry_of(net::PnmlNet) = net.idregistry
decldict(net::PnmlNet) = net.ddict
declarations(net::PnmlNet) =  declarations(decldict(net))

# `pagedict` is all pages in `net`, `page_idset` only for direct pages of net.
pagedict(net::PnmlNet) = net.pagedict # Will be ordered.
page_idset(net::PnmlNet) = net.page_idset # Indices into `pagedict` directly owned by net.

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
pages(net::PnmlNet) = Iterators.filter(pg -> in(pid(pg), page_idset(net)), allpages(net))

"Usually the only interesting page."
firstpage(net::PnmlNet) = first(values(pagedict(net)))

has_tools(net::PnmlNet) = !isnothing(net.toolspecinfos)
toolinfos(net::PnmlNet) = net.toolspecinfos

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
Return `Arc` from 's' to 't' or `nothing`.
Useful for graphs where arcs are represented by a tuple or pair (source,target).
"""
arc(net, s::Symbol, t::Symbol) = begin
    x = Iterators.filter(a -> source(a) === s && target(a) === t, arcs(net))
    isempty(x) ? nothing : first(x)
end

# Iterate IDs of arcs that have given source or target.values(arcdict(net))
function all_arcs(net::PnmlNet, id::Symbol)
    Iterators.map(pid, Iterators.filter(a -> (source(a) === id || target(a) === id),
                                              values(arcdict(net))))
end
function src_arcs(net::PnmlNet, id::Symbol)
    Iterators.map(pid, Iterators.filter(a -> (source(a) === id), values(arcdict(net))))
end
function tgt_arcs(net::PnmlNet, id::Symbol)
    Iterators.map(pid, Iterators.filter(a -> (target(a) === id), values(arcdict(net))))
end

"Forward `inscription` to `arcdict`"
inscription(net::PnmlNet, arc_id::Symbol) = inscription(arcdict(net)[arc_id])

has_refplace(net::PnmlNet, id::Symbol)      = haskey(refplacedict(net), id)
refplace(net::PnmlNet, id::Symbol)          = refplacedict(net)[id]
has_reftransition(net::PnmlNet, id::Symbol) = haskey(reftransitiondict(net), id)
reftransition(net::PnmlNet, id::Symbol)     = reftransitiondict(net)[id]

#------------------------------------------------------------------------------
# DeclDict access
#------------------------------------------------------------------------------
"Return dictionary of `UserOperator`"
useroperators(net::AbstractPnmlNet)  = useroperators(decldict(net))
"Return dictionary of `VariableDecl`"
variabledecls(net::AbstractPnmlNet)  = variabledecls(decldict(net))
"Return dictionary of `NamedSort`"
namedsorts(net::AbstractPnmlNet)     = namedsorts(decldict(net))
"Return dictionary of `ArbitrarySort`"
arbitrarysorts(net::AbstractPnmlNet) = arbitrarysorts(decldict(net))
"Return dictionary of `PartitionSort`"
partitionsorts(net::AbstractPnmlNet) = partitionsorts(decldict(net))
"Return dictionary of `NamedOperator`"
namedoperators(net::AbstractPnmlNet) = namedoperators(decldict(net))
"Return dictionary of `ArbitraryOperator`"
arbitraryops(net::AbstractPnmlNet)   = arbitraryoperators(decldict(net))
"Return dictionary of partitionops (`PartitionElement`)"
partitionops(net::AbstractPnmlNet)   = partitionops(decldict(net))
"Return dictionary of `FEConstant`"
feconstants(net::AbstractPnmlNet)    = feconstants(decldict(net))

"Return dictionary of `MultisetSort`"
multisetsorts(net::AbstractPnmlNet)    = multisetsorts(decldict(net))
"Return dictionary of `ProductSort`"
productsorts(net::AbstractPnmlNet)    = productsorts(decldict(net))
#
#
#
"Lookup variable with `id` in DeclDict."
variabledecl(net::AbstractPnmlNet, id::Symbol) = variabledecls(decldict(net))[id]

"Lookup namedsort with `id` in DeclDict."
namedsort(net::AbstractPnmlNet, id::Symbol)      = namedsorts(decldict(net))[id]
"Lookup arbitrarysort with `id` in DeclDict."
arbitrarysort(net::AbstractPnmlNet, id::Symbol)  = arbitrarysorts(decldict(net))[id]
"Lookup partitionsort with `id` in DeclDict."
partitionsort(net::AbstractPnmlNet, id::Symbol)  = partitionsorts(decldict(net))[id]

"Lookup multisetsort with `id` in DeclDict."
multisetsort(net::AbstractPnmlNet, id::Symbol)  = multisetsorts(decldict(net))[id]
"Lookup productsort with `id` in DeclDict."
productsort(net::AbstractPnmlNet, id::Symbol)   = productsorts(decldict(net))[id]

"Lookup namedop with `id` in DeclDict."
namedop(net::AbstractPnmlNet, id::Symbol)        = namedoperators(decldict(net))[id]
"Lookup arbitraryop with `id` in DeclDict."
arbitraryop(net::AbstractPnmlNet, id::Symbol)    = arbitraryops(decldict(net))[id]
"Lookup partitionop with `id` in DeclDict."
partitionop(net::AbstractPnmlNet, id::Symbol)    = partitionops(decldict(net))[id]
"Lookup feconstant with `id` in DeclDict."
feconstant(net::AbstractPnmlNet, id::Symbol)     = feconstants(decldict(net))[id]
"Lookup useroperator with `id` in DeclDict."
useroperator(net::AbstractPnmlNet, id::Symbol)   = useroperators(decldict(net))[id]

"Lookup operator with `id` in DeclDict.::Symbol May be namedop, feconstant, etc"
operator(net::AbstractPnmlNet, id::Symbol) = operator(decldict(net), id)
"""
    operators(net::AbstractPnmlNet)-> Iterator
Iterate over each operator in the operator subset of declaration dictionaries .
"""
operators(net::AbstractPnmlNet) = operators(decldict(net))
#
#
#
"Does any operator dictionary contain `id`?"
has_operator(net::AbstractPnmlNet, id::Symbol) = has_operator(decldict(net), id)

"""
    has_key(net::AbstractPnmlnet, dict, key::Symbol) -> Bool
Where `dict` is the access method for a dictionary in `DeclDict`.
"""
has_key(net::AbstractPnmlNet, dict, key::Symbol) = haskey(dict(decldict(net)), key)

has_variabledecl(net::AbstractPnmlNet, id::Symbol)   = has_key(decldict(net), variabledecls, id)
has_namedsort(net::AbstractPnmlNet, id::Symbol)      = has_key(decldict(net), namedsorts, id)
has_arbitrarysort(net::AbstractPnmlNet, id::Symbol)  = has_key(decldict(net), arbitrarysorts, id)
has_partitionsort(net::AbstractPnmlNet, id::Symbol)  = has_key(decldict(net), partitionsorts, id)

has_multisetsort(net::AbstractPnmlNet, id::Symbol)   = has_key(decldict(net), multisetsorts, id)
has_productsort(net::AbstractPnmlNet, id::Symbol)    = has_key(decldict(net), productsorts, id)

has_namedop(net::AbstractPnmlNet, id::Symbol)        = has_key(decldict(net), namedoperators, id)
has_arbitraryop(net::AbstractPnmlNet, id::Symbol)    = has_key(decldict(net), arbitraryops, id)
has_partitionop(net::AbstractPnmlNet, id::Symbol)    = has_key(decldict(net), partitionops, id)
has_feconstant(net::AbstractPnmlNet, id::Symbol)     = has_key(decldict(net), feconstants, id)
has_useroperator(net::AbstractPnmlNet, id::Symbol)   = has_key(decldict(net), useroperators, id)


#------------------------------------------------------------------------------
"""
Error if any diagnostic messages are collected. Especially intended to detect semantc error.
"""
function verify(net::PnmlNet, verbose::Bool)
    verbose && println("## verify $(typeof(net)) $(pid(net))")
    errors = String[]
    verify!(errors, net, verbose)
    verify!(errors, decldict(net), verbose, net)
    isempty(errors) || error("verify(net) $(pid(net)) error(s):\n ", join(errors, ",\n "))
    return true
end

function verify!(errors::Vector{String}, net::PnmlNet, verbose::Bool)
    # pagedict
    # netdata
    # page_set
    # toolspecifics
    # extralabels

    # Are the things with PNML IDs in the IDRegistry?
    verify_ids!(errors, "net id", (net,), net)
    verify_ids!(errors, "pages id", pages(net), net)
    verify_ids!(errors, "allpages id", allpages(net), net)
    verify_ids!(errors, "places id", places(net), net)
    verify_ids!(errors, "transition id", transitions(net), net)
    verify_ids!(errors, "arcs id", arcs(net), net)
    verify_ids!(errors, "refplaces id", refplaces(net), net)
    verify_ids!(errors, "reftransitions id", reftransitions(net), net)

    verify!(errors, decldict(net), verbose, net)

    verify!(errors, net.declaration, verbose, net)

    # Call net object's verify method.
    foreach(x -> verify!(errors, x, verbose, net), allpages(net))
    foreach(x -> verify!(errors, x, verbose, net), places(net))
    foreach(x -> verify!(errors, x, verbose, net), transitions(net))
    foreach(x -> verify!(errors, x, verbose, net), arcs(net))
    foreach(x -> verify!(errors, x, verbose, net), refplaces(net))
    foreach(x -> verify!(errors, x, verbose, net), reftransitions(net))

    !isnothing(toolinfos(net)) &&
        foreach(x -> verify!(errors, x, verbose, net), toolinfos(net))
    # foreach(x -> verify!(errors, x, verbose, net), extralabels(net))

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
    verify_ids!(errors, str, iterable, net::AbstractPnmlNet) -> Vector{String}

Iterate over `iterable` testing that `pid` is registered in `net`.
`str` used in message appended to `errors` vector of strings.
"""
function verify_ids!(errors, str::AbstractString, iterable, net::AbstractPnmlNet)
    for x in iterable
        if !isregistered(registry_of(net), pid(x))
            push!(errors, string(str, " ", pid(x), " not registered")::String)
        end
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

show_sorts(net::AbstractPnmlNet) = show_sorts(decldict(net))
