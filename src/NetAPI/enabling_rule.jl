# Enableing Rule

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
            single = only(multiset(mark))
            eltype(single) <: PnmlMultiset && error("recursive PnmlMultisets not allowed here")
            return single # Replace mark with the wrapped PnmlMultiset
        end
    # else
    #     @warn "mark in not a PnmlMultiset" mark
    end
    return mark
end

#^+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
"""
    binding_value_sets(net::PnmlNet, marking) -> Vector{Dict{REFID,Any}}

Return dictionary with transaction ID is key and value is binding set for variables of that transition.
Each variable of an enabled transition will have a non-empty binding.
"""
function binding_value_sets(net::PnmlNet, marking)
    bv_sets = Vector{Dict{REFID,Any}}() # One dictionary for each transition.
    # The order of transitions is maintained.
    for t in transitions(net)::Transition
        bvalset = Dict{REFID,Set{eltype(basis)}}() # For this transition
        for a in PNML.preset(net, t)::Arc
            adj = adjacent_place(net, a)
            placesort = sortref(adj)
            vs = vars(inscription(a))::Tuple

            for v in vs # inscription that is not a ground term
                equal(placesort, v) || error("sorts not equal for variable $v and marking $placesort")
                #? for creating Ref need index into product sort/PnmlTuple
                bvs = Dict{REFID,Set{eltype(basis)}}() # For this arc
                # bind elements of the multiset to the variable when the multiplicities match.
                for el in keys(marking[pid(adj)])
                    # each element with enough multiplicity can be bound.
                    if multiplicity(marking[pid(adj)], el) >= length(filter(==(v), vs))
                        push!(bvs[v], el)
                    end
                end

                for k in keys(bvs)
                    bvalset[k] = haskey(bvalset, k) ? intersect(bvalset[k], bvs[k]) : bvs[k]
                end
            end
            # Empty binding value set means the transition is not enabled.
            isempty(vars) || !isempty(bvalset) || error("expected non-empty binding value set")
        end
        push!(bv_sets, bvalset)
    end
    return bv_sets
end

# function variable_subs(tr::Transition, marking)
#     #@error("implement me variable_subs($tr, $marking)")
#     return varsubs(tr)
# end

#^+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
"""
    labeled_places(net::PnmlNet)

Return Vector of place_id=>marking_value.
"""
function labeled_places end

function labeled_places(net::PnmlNet, markings)
    # create vector place_id=>marking_value
    # initial_markings(net) becomes vector of marking_value
    [k=>v for (k,v) in zip(map(pid, PNML.places(net)), markings)]
end


"""
    enabled(::PnmlNet, marking) -> Vector{Bool}

Return vector of booleans where `true` means the matching transition is enabled at current `marking`.
Has the same order as the `transitions` dictionary.
Used in the firing rule.
Update tr.vars Set and tr.varsubs NamedTuple.
"""
function enabled end

function enabled(net::PnmlNet, marking) #!::Vararg{Union{Pair,Tuple}})
    varsub = NamedTuple() # There are no varibles possible here.
    marking # vector or tuple with element per place
    d = Dict(labeled_places(net, marking))
    evector = Bool[]
    for tr in transitions(net)
        trid = pid(tr)
        enabled = true # Assume all transitions possible.
        e = all(d[p] >= inscription(arc(net,p,trid))(varsub) for p in PNML.preset(net, trid))
        push!(evector, e)
    end
    return evector
    # Bool[all(p -> d[p] >= inscription(arc(net,p,t))(varsub),
    #                                     PNML.preset(net, t)) for t in transition_idset(net)]
end

function enabled(net::PnmlNet{<:AbstractHLCore}, marking)
    evector = Bool[]
    mark_dict = Dict(labeled_places(net, marking))
    for tr in transitions(net)
        trid = pid(tr)
        enabled = true # Assume all transitions possible.
        tr.varsubs = NamedTuple[]

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
            mark      = unwrap_pmset(mark_dict[placeid]) #! Possibly extract a singlton.
            arc_vars  = Multiset(Labels.variables(inscription(ar))...) # Count variables.
            #! No-variable arcs must still be tested for place marking >= inscription & condition.
            isempty(arc_vars) ||
                union!(tr.vars, keys(arc_vars)) # Only variable REFID is stored in transaction.

            arc_bvs   = OrderedDict{REFID, Multiset{Symbol}}() # Empty per-arc binding.

            placesort = sortref(place(net, placeid)) # TODO create exception
            enabled &= get_arc_bvs!(arc_bvs, arc_vars, placesort, mark, net)
            enabled || break
            enabled &= accum_varsets!(bvs, arc_bvs) # Transaction accumulates/intersects arc bindings.
            enabled || break
        end # preset arcs
        #& XXX variable substitutions fully specified by preset of transition XXX
        #& tr.vars is complete. bvs has valid substitutions (if any exist)

        vid = tuple(keys(bvs)...) # names of tuple elements are variable REFIDs

        if enabled
            #! 2st stage of enabling rule has succeded. (place marking >= inscription)
            for arc in Iterators.filter(a -> (target(a) === trid), values(arcdict(net)))
                placeid   = source(arc) # adjacent place
                mark      = mark_dict[placeid]

                # Inscription evaluates to multiset element of sufficent multiplicity.
                # Condition evaluates to `true`
                if isempty(tr.vars) # 0-ary operators
                    # This includes the non-HL net types that do not have variables.
                    inscription_val = _cvt_inscription_value(pntd(net), arc,
                                                    zero_marking(place(net, placeid)),
                                                    NamedTuple())
                    mi_val = mark >= inscription_val # multiset >= multiset or number >= number
                    c_val = eval(toexpr(term(condition(tr)), NamedTuple(), tr.net))
                    enabled &= mi_val && c_val
                else
                    # Use the transition-level variable substution bindings `bvs`.
                    # Iterate over the cartesian product to produce a list of candidate firings.
                    # A candidate firing is a NamedTuple
                    vtup = tuple(values(bvs)...) # Tuple of Multisets{PnmlMultiset}
                    # If an element is a PnmlMultiset it probably is a singleton. Treat as literal value.
                    sub1 = tuple((keys.(vtup))...) # substitutions
                    vsubiter = Iterators.product(sub1...)
                    foreach(vsubiter) do  params
                        # Is params a tuple
                        vsub = namedtuple(vid, params) # names, values
                        i_val = _cvt_inscription_value(pntd(net), arc,
                                            zero_marking(place(net, placeid)),
                                            vsub)
                        mark = unwrap_pmset(mark)

                        #? Do we want <= or is it issubset(A,B)?
                        mi_val = issubset(i_val, mark)
                        c_val = eval(toexpr(term(condition(tr)), vsub, tr.net))

                        if mi_val && c_val
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

        # if enabled
        #     # Condition passed
        #     printstyled("ENABLED ", length(tr.varsubs), " variable substitution candidates\n"; color=:green)
        # else
        #     printstyled("DISABLED\n"; color=:red)
        # end
        push!(evector, enabled)
        # println("----------------------------------------------------------")
    end # for tr
    #@show evector
    return evector
end


"""
    get_arc_bvs!(arc_bvs, arc_vars, placesort, mark, net) -> Bool

Fill `arc_bvs` with an entry for each key in `arc_vars`.
Return `true` if no variables are present or all variables have at least 1 substution.
"""
function get_arc_bvs!(arc_bvs::AbstractDict, arc_vars, placesort, mark, net)
    for v in keys(arc_vars) # Each variable must have a non-empty substitution.
        #! variable sorts are never PnmlTuples. Just one sort.
        arc_bvs[v] = Multiset{Symbol}() # Empty substution set.
        var_refid = refid(sortref(variabledel(net, v)))

        # Verify variable sort matches placesort.
        if sortof(placesort) isa ProductSort
            #! Variable is PnmlTuple element. Variable sort is one of the sorts of the product.
            any(==(var_refid), Sorts.sorts(sortof(placesort, net))) ||
                    error("none of tuple are equal sorts of $var_refid: ",
                            Sorts.sorts(sortof(placesort, net)))
        else
            placesort !== sortref(variabledecl(net, v)) &&
                error("not equal sorts ($placesort, $(sortref(variabledecl(net, v))))")
        end

        for (el,mu) in pairs(multiset(mark))
            #! arc_bvs counts possible substitutions in source place's marking.
            # Multiple of same variable in inscription expression means arc_bvs only includes
            # elements with a multiplicity at least as that large.
            if mu >= arc_vars[v] # Variable multiplicity is per-arc, value is shared among arcs.
                if el isa Tuple
                    # Select the tuple element matching variable sort.
                    # Standard PnmlTuple are pairs. We allow tuple of at least one element.
                    for e in el #? PnmlMultiset?
                        if refid(e) == var_refid
                            e2 = e()
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
