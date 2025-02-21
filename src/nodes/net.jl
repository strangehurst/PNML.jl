"""
$(TYPEDEF)
$(TYPEDFIELDS)

One Petri Net of a PNML model.
"""
@kwdef mutable struct PnmlNet{PNTD<:PnmlType, P, T, A, RP, RT}
    type::PNTD
    id::Symbol
    pagedict::OrderedDict{Symbol, Page{PNTD, P, T, A, RP, RT}} # Shared by pages, holds all pages.
    netdata::PnmlNetData{PNTD} #!, P, T, A, RP, RT} # Shared by pages, holds all places, transitions, arcs, refs
    page_set::OrderedSet{Symbol} # Unordered keys of pages in pagedict owned by this net.
    # Top-level of a tree with PnmlNetKeys in Pages.
    #
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
pagedict(n::PnmlNet) = n.pagedict # Will be ordered.
page_idset(n::PnmlNet)  = n.page_set #! Not ordered! Dictionaries in netdata ARE ordered.

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

#-----------------------------------------------------------------
# Given x ∈ S ∪ T
#   - the set •x = {y | (y, x) ∈ F } is the preset of x.
#   - the set x• = {y | (x, y) ∈ F } is the postset of x.

"""
    preset(net, id) -> Iterator

Iterate ids of input (arc's source) for output transition or place `id`.

See [`in_inscriptions`](@ref) and [`transition_function`](@ref).
"""
preset(net::PnmlNet, id::Symbol) = begin
    Iterators.map(x -> source(arcdict(net)[x]), tgt_arcs(net, id))
end

"""
    postset(net, id) -> Iterator

Iterate ids of output (arc's target) for source transition or place `id`.

See [`out_inscriptions`](@ref) and [`transition_function`](@ref).
"""
postset(net::PnmlNet , id::Symbol) = begin
    Iterators.map(x -> target(arcdict(net)[x]), src_arcs(net, id))
end

#------------------------------------------------------------------------------
# Rewrite
#------------------------------------------------------------------------------

"""
    accum_varsets!(bvs, arc_bvs) -> Bool
Collect variable bindings, intersecting among arcs.
Return enabled status of false if any variable does not have a substitution.
"""
function accum_varsets!(bvs::OrderedDict, arc_bvs::OrderedDict)
    for v in keys(arc_bvs) # Each variable found in arc is merged into transaction set.
        accum_varset!(bvs, arc_bvs, v)
    end
    # Transition enabled when all(s->cardinality(s) > 0, values(bvs)).
    all(!isempty, values(bvs))
end

"Collect/intersect binding of one arc variable binding set."
function accum_varset!(bvs::OrderedDict, arc_bvs::OrderedDict, v::REFID)
    @assert arc_bvs[v] != 0 # This arc must satisfy all its variables.
    if !haskey(bvs, v) # Previous arcs did not have variable.
        bvs[v] = arc_bvs[v] # Initial value from 1st use.
    else
        @assert eltype(bvs[v]) == eltype(arc_bvs[v]) # Same type is expected.
        intersect!(bvs[v], arc_bvs[v])
    end
end

"""
    unwrap_pmset(mark) -> Multiset

If marking wraps a PnmlMultiset, extract a singleton.
"""
function unwrap_pmset(mark)
    if mark isa PnmlMultiset
        # That contains PnmlMultisets
        if eltype(mark) <: PnmlMultiset
            # In the wrapped Multiset we allow one singleton PnmlMultiset
            # println("\n\neltype(mark) isa PnmlMultiset\n") #! Log
            single = only(multiset(mark))
            @warn "unwrapping PnmlMultiset" single
            eltype(single) <: PnmlMultiset && error("recursive PnmlMultisets not allowed here")
            return single # Replace mark with the wrapped PnmlMultiset
        end
    else
        @warn "mark in not a PnmlMultiset" mark
    end
    return mark
end

"""
    get_arc_bvs!(arc_bvs, arc_vars, placesort, mark) -> Bool

Fill `arc_bvs` with entry for each `arc_vars`
"""
function get_arc_bvs!(arc_bvs, arc_vars, placesort, mark)
    for v in keys(arc_vars) # Each variable must have a non-empty substitution.
        #! arc_bvs[v] = Multiset{eltype(mark)}() # Empty substution set.
        #! variable sorts are never PnmlTuples. Just one sort. UserSort wraps REFID.
        arc_bvs[v] = Multiset{Symbol}() # Empty substution set.
        varrefid = refid(sortref(variable(v)))
        println("   v  $(repr(v)) isa $(sortref(variable(v))), refid = $varrefid")

        # Verify variable sort matches placesort.
        if sortof(placesort) isa ProductSort
            #! Variable is PnmlTuple element. Variable sort is one of the sorts of the product.
            # for s in sorts(sortof(placesort)); @show s; end
            # @show sorts(sortof(placesort))
            any(==(varrefid), sorts(sortof(placesort))) ||
                    error("none of tuple are equal sorts of $varrefid: $(sorts(sortof(placesort))))")
        else
            placesort !== sortref(variable(v)) &&
                error("not equal sorts ($placesort, $(sortref(variable(v))))")
        end

        for (el,mu) in pairs(multiset(mark))
            println("   el  ", el)
            #! arc_bvs counts possible substitutions in source place's marking.
            # Multiple of same variable in inscription expression means arc_bvs only includes
            # elements with a multiplicity at least as that large.
            if mu >= arc_vars[v] # Variable multiplicity is per-arc, value is shared among arcs.
                if el isa Tuple
                    # Select the tuple element matching variable sort.
                    # Standard PnmlTuple are pairs. We allow tuple of at least one element.
                    for e in el #? PnmlMultiset?
                        if refid(e) == varrefid
                            e2 = e()
                            println("   e2  ", e2)
                            push!(arc_bvs[v], e2) # Add value to count of substitutions.
                        end
                    end
                else #! el may be a PnmlMultiset
                    push!(arc_bvs[v], el) # Add value to count of substitutions.
                end
            end
        end
        if !isempty(arc_vars) && isempty(arc_bvs[v])
            return false # There are variables and one of them has no substitution.
        end
    end
    return true # No variables or all of them have at least 1 substution.
end

"""
    enabledXXX(net::PnmlNet, marking)

Update tr.vars, tr.varsubs for every transition `tr` in `net` using `marking`.
"""
function enabledXXX(net::PnmlNet, marking)
    evector = Pair{REFID,Bool}[]
    for tr in transitions(net)
        trid = pid(tr)
        enabled = true # Assume all transitions possible.
        tr.varsubs = NamedTuple[]

        println("\nt ",repr(trid), " ", repr(condition(tr))) #  #! variable substitution needed for condition
        println("   tgts $(repr(trid)) = ", map(a->(a=>variables(inscription(arc(net, a)))), tgt_arcs(net, trid)))
        println("   srcs $(repr(trid)) = ", map(a->(a=>variables(inscription(arc(net, a)))), src_arcs(net, trid)))

        #!2025-01-27 JDH moved tr_vars to Transition tr.vars
        bvs = OrderedDict{REFID, Any}() # During enabling rule, bvs maps variable to a set of elements.
        #~ marking = PnmlMultiset{B, T}(Multiset{T}(T() => 1)) singleton
        # varsub maps a variable to 1 element of multiset(marking[trid]) when enabling/firing transition.
        # Multiset type set from first use
        # Operator parameters are an ordered collection of value, sort. {variables!}
        # Where sort is a REFID to a variable declaration with name and sort.

        # marking[placeid][element] > 0 (multiplicity >= arc_var matching variableid)

        # Get transition variable substitution from preset arcs.
        for ar in Iterators.filter(a -> (target(a) === trid), values(arcdict(net)))
            placeid   = source(ar) # adjacent place
            mark      = unwrap_pmset(marking[placeid]) #! Possibly extract a singlton.
            # println("   arc ", repr(pid(ar)), " : ", repr(placeid), " -> ", repr(trid))
            # println("      marking = ", mark)

            arc_vars  = Multiset(variables(inscription(ar))...) # Count variables.
            #! No variable arcs must still be tested for place marking >= inscription & condition.
            isempty(arc_vars) ||
                union!(tr.vars, keys(arc_vars)) # Only variable REFID is stored in transaction.

            arc_bvs   = OrderedDict{REFID, Multiset{Symbol}}() # Per-arc binding.

            placesort = sortref(place(net, placeid)) # TODO create exception
            enabled &= get_arc_bvs!(arc_bvs, arc_vars, placesort, mark)
            enabled || break
            enabled &= accum_varsets!(bvs, arc_bvs) # Transaction accumulates/intersects arc bindings.
            enabled || break
        end # preset arcs
        #& XXX variable substitutions fully specified by preset of transition XXX
        #& tr.vars is complete. bvs has valid substitutions (if any exist)

        @show vid = tuple(keys(bvs)...) # names of tuple elements are variable REFIDs
        length(tr.vars) > 1 &&
            printstyled("\n=========\nMultiple transition variables\n=========\n\n"; color=:bold)
        #@show tr.vars vid
        # foreach(println, pairs(bvs))

        if enabled
            #! 2st stage of enabling rule has succeded. (place marking >= inscription)
            println("\n----------------------------------------------------------")
            for ar in Iterators.filter(a -> (target(a) === trid), values(arcdict(net)))
                placeid   = source(ar) # adjacent place
                mark      = marking[placeid]
                println("ar ", repr(pid(ar)), " : input place ", repr(placeid))
                # @show mark

                # Inscription evaluates to multiset element of sufficent multiplicity.
                # Condition evaluates to `true`
                if isempty(tr.vars)
                    # This includes the non-HL net types that do not have variables.
                    # 0-ary operators
                    #@show term(inscription(ar))
                    inscription_val = eval(toexpr(term(inscription(ar)), NamedTuple()))
                    mi_val = mark >= inscription_val # multiset >= multiset or number >= number
                    !mi_val && println("mark < inscription_val.") #! debug
                    #@show term(condition(tr))
                    condition_val = eval(toexpr(term(condition(tr)), NamedTuple()))
                    !condition_val && println("condition false.") #! debug
                    enabled &= mi_val && condition_val
                else
                    #@show pairs(multiset(mark))
                    # Use the transition-level variable substution bindings `bvs`.
                    # Iterate over the cartesian product to produce a list of candidate firings.
                    # A candidate firing is a NamedTuple
                    # foreach(println,  pairs(bvs))
                    #@show vid
                    vtup = tuple(values(bvs)...) # Tuple of Multisets{PnmlMultiset}
                    # If an element is a PnmlMultiset it probably is a singleton. Treat as literal value.
                    # println()
                    sub1 = tuple((keys.(vtup))...) # substitutions
                    # println("sub1"); foreach(println, sub1)
                    #!vsubiter = Iterators.product(tuple(collect(keys.(values(bvs)))...))
                    vsubiter = Iterators.product(sub1...)
                    #println()
                    #@show collect(vsubiter)
                    foreach(vsubiter) do  params
                        #println()
                        #@show params #typeof(params)
                        # Is params a tuple
                        @show vsub = namedtuple(vid, params) # names, values
                        @show term(inscription(ar)) toexpr(term(inscription(ar)), vsub)

                        inscription_val = eval(toexpr(term(inscription(ar)), vsub))
                        @show inscription_val

                        mark = unwrap_pmset(mark)


                        #println()
                        #? Do we want <= or is it issubset(A,B)?
                        #println("issubset(inscription_val, mark)")
                        mi_val = issubset(inscription_val, mark)
                        # println("inscription_val <= mark")
                        # @show mi_val = inscription_val <= mark
                        !mi_val && println("mark ⊂ inscription_val") #! debug

                        @show condition_val = eval(toexpr(term(condition(tr)), vsub))
                        !condition_val && println("condition false.") #! debug

                        if mi_val && condition_val
                            push!(tr.varsubs, vsub)
                        else
                            enabled = false
                        end
                    end
                    #@show tr.varsubs
                end
            end
            #! REMEMBER marking multiset element may be a PnmlMultiset.
        end

        if enabled
            # Condition passed
            printstyled("ENABLED ", length(tr.varsubs), " variable substitution candidates\n"; color=:green)
        else
            printstyled("DISABLED\n"; color=:red)
        end
        @show push!(evector, trid => enabled)
        println("----------------------------------------------------------")
    end # for tr
  return evector
end

"""
    rewriteXXX(net, marking)

Rewrite PnmlExpr (TermInterface) expressions.
"""
function rewriteXXX(net::PnmlNet, marking)
    printstyled("\n## rewrite PnmlNet ", repr(pid(net)), " ", pntd(net), "\n"; color=:magenta)

    #println("OPERATORS")
    @show collect(operators()) # Accesses ScopedValue, return irterator

    @show DECLDICT[]

    println("\nPLACES")
    for pl in places(net)
        println("p ",repr(pid(pl)), " marking ",  marking[pid(pl)])
        # other place labels: capacity expression
    end

    #~bv_sets = Dict{REFID, SubstitutionDict}() # keys are transaction id
    # Each SubstitutionDict is a dictionary of multisets,
    #   key is variable REFID
    #   value is set of substitutions for that REFID (with multiplicity via multiset)
    #
    # Used as working storage that is a valid variable substitution only at the end of the algorythim.
    #
    # algorythim iterates over transitions of net
    # only enabled transitions remain in bv_sets at end of algorythim

    # println("\nARCS")
    # for ar in arcs(net)
    #     println("a ",repr(pid(ar)), " ", repr(ar.inscription), " vars = ",variables(ar.inscription)) # expression
    #     #@show toexpr(term(ar.inscription), subdict)
    # end

    println("\nTRANSITIONS")
    enabledXXX(net, marking)

    # println()
    # println("postset of $(repr(trid))")
    # for placeid in postset(net, trid)
    #     a = arc(net, trid, placeid)
    #     if !isnothing(a)
    #         println("   arc to ", repr(placeid), " variables ", variables(a.inscription)) #! SubstitutionDict
    #     end
    # end
    # namedoperators
    # arbitraryops
    # partitionopsoperators(dd) = Base.Iterators.Flatten{Base.Generator{Base.Generator{NTuple{4, Symbol}, PNML.var"#3#4"{DeclDict}}, typeof(values)}}(Base.Generator{Base.Generator{NTuple{4, Symbol}, PNML.var"#3#4"{DeclDict}}, typeof(values)}(values, Base.Generator{NTuple{4, Symbol}, PNML.var"#3#4"{DeclDict}}(PNML.var"#3#4"{DeclDict}(DeclDict(
    #
    printstyled("##  \n"; color=:magenta)
    println()

end

#------------------------------------------------------------------------------
"""
Error if any diagnostic messages are collected. Especially intended to detect semantc error.
"""
function verify(net::PnmlNet; verbose::Bool = CONFIG[].verbose)
    #verbose && println("verify PnmlNet $(pid(net))"); flush(stdout)
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

#------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------
# Construct Types
#------------------------------------------------------------------------------
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
