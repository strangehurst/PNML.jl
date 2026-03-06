# Enabling Rule

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

Return dictionary with transaction ID as key
and value is binding set for variables of that transition.
Each variable of an enabled transition will have a non-empty binding.
"""
function binding_value_sets(net::PnmlNet, marking)
    bv_sets = Vector{Dict{REFID, Any}}() # One dictionary for each transition.

    # The order of transitions is maintained.
    for t in transitions(net)::Transition
        bval_set = Dict{REFID, Set{eltype(basis)}}() # For this transition

        for a in preset(net, t)::Arc
            adj = adjacent_place(net, a)
            placesort = sortref(adj)
            vs = variables(inscription(a))

            for v in vs # inscription that is not a ground term
                equal(placesort, v) ||
                    error("sorts not equal for variable $v and marking $placesort")
                #? for creating Ref need index into product sort/PnmlTuple
                bvs = Dict{REFID, Set{eltype(basis)}}() # For this arc
                # bind elements of the multiset to the variable when the multiplicities match.
                for el in keys(marking[pid(adj)])
                    # each element with enough multiplicity can be bound as a substitution.
                    if multiplicity(marking[pid(adj)], el) >= length(filter(==(v), vs))
                        push!(bvs[v], el)
                    end
                end

                for k in keys(bvs)
                    bval_set[k] = if haskey(bval_set, k)
                        intersect(bval_set[k], bvs[k])
                    else
                         bvs[k]
                    end
                end
            end
            # Empty binding value set means the transition is not enabled.
            isempty(vars) || !isempty(bval_set) ||
                error("expected non-empty binding value set")
        end
        push!(bv_sets, bval_set)
    end
    return bv_sets
end

# function variable_subs(tr::Transition, marking)
#     #@error("implement me variable_subs($tr, $marking)")
#     return varsubs(tr)
# end

#^+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
"""
    labeled_places(net::PnmlNet, marking_vector)

Return Vector of place_id=>marking_value of that pace.
"""
function labeled_places(net::PnmlNet, markings)
    [k=>v for (k,v) in zip(map(pid, places(net)), markings)]
end


"""
    enabled(::PnmlNet, marking) -> Vector{Bool}

Return vector of booleans where `true` means the matching transition is enabled at current `marking`.
Has the same order as the `transitions` dictionary.
Used in the firing rule.
Update tr.vars Set and tr.varsubs NamedTuple.
"""
function enabled end

function enabled(net::AbstractPnmlNet, marking)
    e_dict = OrderedDict{Symbol, Bool}(id=>true for (id,t) in pairs(transitiondict(net)))
    mark_dict = OrderedDict{Symbol, value_type(Marking, net)}(labeled_places(net, marking))
    #TODO other filters reducing work done by token_load!
    token_load!(e_dict, mark_dict, net)
    #TODO other filters modifying e_dict
    return collect(values(e_dict))
end

"""
    token_load!(enabled_dict, mark_dict, net::AbstractPnmlNet)

Update each enabled transition's state in `enabled_dict` by testing that
all its input places have enough tokens.
"""
function token_load! end

function token_load!(enabled_dict::AbstractDict,
                     mark_dict::AbstractDict,
                     net::AbstractPnmlNet)
    varsub = NamedTuple() # There are no varibles possible here.
    for t in transitions(net)
        # Do all input places of enabled transitions have enough tokens?
        tid = pid(t)
        if enabled_dict[tid]
            # evaluate preset inscription expressions
            enabled_dict[tid] &= all(mark_dict[p] >= inscription(arc(net, p, tid))(varsub)
                                    for p in preset(net, tid))
        end
    end
    return enabled_dict
end

function token_load!(enabled_dict::AbstractDict,
                     mark_dict::AbstractDict,
                     net::PnmlNet{<:AbstractHLCore})

   for tr in transitions(net)
        trid = pid(tr)
        empty!(tr.varsubs) #~ clear cached NamedTuple[]
        enabled_dict[trid] || continue
        enabled = enabled_dict[trid]

        #!2025-01-27 JDH moved tr_vars to Transition tr.vars
        bvs = OrderedDict{REFID, Any}() # During enabling rule, bvs maps variable to a set of elements.
        #~ marking = PnmlMultiset{B, T}(Multiset{T}(T() => 1)) singleton
        # varsub maps a variable to 1 element of multiset(marking[trid]) when enabling/firing transition.
        # Multiset type set from first use
        # marking[placeid][element] > 0 (multiplicity >= arc_var matching variableid)

        # Get transition variable substitution from preset arcs.
        for placeid in preset(net, trid)
            ar = arc(net, placeid, trid)
            mark     = unwrap_pmset(mark_dict[placeid]) #! Possibly extract a singlton.
            arc_vars = Multiset(variables(inscription(ar))...) # Count variables.
            #! No-variable arcs must still be tested for place marking >= inscription & condition.
            isempty(arc_vars) ||
                union!(tr.vars, keys(arc_vars)) # Only variable REFID is stored in transaction.

            # Empty per-arc binding.
            arc_bvs = OrderedDict{REFID, Multiset{Symbol}}()

            placesort = sortref(place(net, placeid))
            enabled &= get_arc_bvs!(arc_bvs, arc_vars, placesort, mark, net)
            enabled || break
            enabled &= accum_varsets!(bvs, arc_bvs) # Transaction accumulates/intersects arc bindings.
            enabled || break
        end # preset arcs
        #& XXX variable substitutions fully specified by preset of transition XXX
        #& tr.vars is complete. bvs has valid substitutions (if any exist)

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
                        vsub = namedtuple(tuple(keys(bvs)...), params)
                        i_val = _cvt_inscription_value(pntd(net), arc,
                                            zero_marking(place(net, placeid)),
                                            vsub)
                        mark = unwrap_pmset(mark)

                        #? Do we want <= or is it issubset(A,B)?
                        mi_val = issubset(i_val, mark)
                        c_val = eval(toexpr(term(condition(tr)), vsub, tr.net)) #!#

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
        enabled_dict[trid] = enabled

        # if enabled
        #     # Condition passed
        #     printstyled("ENABLED ", length(tr.varsubs), " variable substitution candidates\n"; color=:green)
        # else
        #     printstyled("DISABLED\n"; color=:red)
        # end
    end # for tr
    return enabled_dict
end


"""
    get_arc_bvs!(arc_bvs, arc_vars, placesort, mark, net) -> Bool

Fill `arc_bvs` with an entry for each key in `arc_vars`.
Return `true` if no variables are present or all variables have at least 1 substition.
Indicates that transition is able to fire (enabled fro selection to fire).
"""
function get_arc_bvs!(arc_bvs::AbstractDict, arc_vars::Multiset, placesort::SortRef, mark, net)
    for v in keys(arc_vars)
        # Each variable must have a non-empty substitution.
        #! variable sorts are never ProductSort. Just one sort.
        arc_bvs[v] = Multiset{Symbol}() # Start with empty substution set for variable.
        v_decl = variabledecl(net, v)
        v_sortref = sortref(v_decl)
        v_refid = refid(v_sortref)

        # Verify variable sort matches placesort.
        if isproductsort(placesort)
            any(==(v_refid), Sorts.sorts(sortof(placesort, net))) ||
                    error("none of product sorts are equal to $v_refid: ",
                            Sorts.sorts(sortof(placesort, net)))
        else
            placesort !== v_sortref &&
                error("not equal sorts ($placesort, $v_sortref)")
        end

        # Examine mark
        for (element, multiplicity) in pairs(multiset(mark))
            @show typeof element
            #! arc_bvs counts possible substitutions in source place's marking.
            # Multiple of same variable in inscription expression means
            # arc_bvs only includes mark elements with multiplicity at least as that large.
            if multiplicity >= arc_vars[v]
                # Variable multiplicity is per-arc, value is shared among arcs.
                if element isa Tuple # mark is a ProductSort.
                    # Select the tuple member(s) matching variable sort.
                    for expr in element
                        if refid(expr) == v_refid
                            push!(arc_bvs[v], expr()) # Add value of expr to set.
                        end
                    end
                else #! el may be a PnmlMultiset
                    push!(arc_bvs[v], element) # Add value to count of substitutions.
                end
            end
        end

        if !isempty(arc_vars) && isempty(arc_bvs[v])
            return false # There are variables and one of them has no substitution.
        end
    end
    return true # No variables or all of them have at least 1 substution.
end
