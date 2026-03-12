# Enabling Rule

"""
    accum_tr_var_binding_sets!(tr_var_binding_set, arc_var_binding_set) -> Bool

Collect variable bindings, intersecting among arcs.
Return enabled status of false if any variable does not have a substitution.
"""
function accum_tr_var_binding_sets!(tr_var_binding_set::OrderedDict,
                                    arc_var_binding_set::OrderedDict)
    # Each variable found in arc is merged into transaction set.
    for v in keys(arc_var_binding_set)
        accum_tr_var_binding_set!(tr_var_binding_set, arc_var_binding_set, v)
    end
    # Transition enabled when all(s->cardinality(s) > 0, values(tr_var_binding_set)).
    all(!isempty, values(tr_var_binding_set))
end

"Collect/intersect binding of one arc variable binding set for variable `v`."
function accum_tr_var_binding_set!(tr_var_binding_set::OrderedDict,
                                   arc_var_binding_set::OrderedDict,
                                   v::REFID)
    @assert arc_var_binding_set[v] != 0 # This arc must satisfy all its variables.
    if !haskey(tr_var_binding_set, v)
        tr_var_binding_set[v] = arc_var_binding_set[v] # Initial value from 1st use.
    else
        @assert eltype(tr_var_binding_set[v]) == eltype(arc_var_binding_set[v])
        intersect!(tr_var_binding_set[v], arc_var_binding_set[v])
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
            single = only(multiset(mark))
            eltype(single) <: PnmlMultiset &&
                error("recursive PnmlMultisets not allowed here")
            return single # Replace mark with the wrapped PnmlMultiset
        end
    end
    return mark
end

#^+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# """
#     binding_value_sets(net::PnmlNet, marking) -> Vector{Dict{REFID,Any}}

# Return dictionary with transaction ID as key
# and value is binding set for variables of that transition.
# Each variable of an enabled transition will have a non-empty binding.
# """
# function binding_value_sets(net::PnmlNet, marking)
#     bv_sets = Vector{Dict{REFID, Any}}() # One dictionary for each transition.

#     # The order of transitions is maintained.
#     for t in transitions(net)::Transition
#         bval_set = Dict{REFID, Set{eltype(basis)}}() # For this transition

#         for a in preset(net, t)::Arc
#             adj = adjacent_place(net, a)
#             placesort = sortref(adj)
#             vs = variables(inscription(a))

#             for v in vs # inscription that is not a ground term
#                 equal(placesort, v) ||
#                     error("sorts not equal for variable $v and marking $placesort")
#                 #? for creating Ref need index into product sort/PnmlTuple
#                 tr_var_binding_set = Dict{REFID, Set{eltype(basis)}}() # For this arc
#                 for el in keys(marking[pid(adj)])
#                     # each element with enough multiplicity can be bound as a substitution.
#                     if multiplicity(marking[pid(adj)], el) >= length(filter(==(v), vs))
#                         push!(tr_var_binding_set[v], el)
#                     end
#                 end

#                 for k in keys(tr_var_binding_set)
#                     bval_set[k] = if haskey(bval_set, k)
#                         intersect(bval_set[k], tr_var_binding_set[k])
#                     else
#                          tr_var_binding_set[k]
#                     end
#                 end
#             end
#             # Empty binding value set means the transition is not enabled.
#             isempty(vars) || !isempty(bval_set) ||
#                 error("expected non-empty binding value set")
#         end
#         push!(bv_sets, bval_set)
#     end
#     return bv_sets
# end

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

Return vector of booleans where `true` means the matching transition
is enabled at current `marking`. Has the same order as the `transitions` dictionary.
Used in the firing rule.



Update tr.vars Set and tr.varsubs, NamedTuple.
"""
function enabled end

function enabled(net::AbstractPnmlNet, marking)
    # Start by assuming all transitions are enabled.
    # dictionary with key of transaction id, value of enabled state boolean
    e_dict = OrderedDict{Symbol, Bool}(id=>true for (id,t) in pairs(transitiondict(net)))

    # dictionary with key of place id, value of its marking value (from marking vector)
    mark_dict = OrderedDict{Symbol, value_type(Marking, net)}(labeled_places(net, marking))

    # filters
    #TODO other filters reducing work done by token_load!
    sufficient_tokens!(e_dict, mark_dict, net)
    transition_guard!(e_dict, mark_dict, net)
    #TODO other filters modifying e_dict
    return collect(values(e_dict))
end

"""
    transition_guard!(enabled_dict, mark_dict, net::AbstractPnmlNet)

Update each enabled transition's state in `enabled_dict` by testing its condition.
"""
function transition_guard! end
function transition_guard!(enabled_dict::AbstractDict, # transaction id => boolean
                           mark_dict::AbstractDict,    # place id => marking value
                           net::PnmlNet)
    # Non-high-level do not have conditions. Do they hve other guards?
    return enabled_dict
end
function transition_guard!(enabled_dict::AbstractDict, # transaction id => boolean
                           mark_dict::AbstractDict,    # place id => marking value
                           net::PnmlNet{<:AbstractHLCore})
    return enabled_dict
end

"""
    sufficient_tokens!(enabled_dict, mark_dict, net::AbstractPnmlNet)

Update each enabled transition's state in `enabled_dict` by testing that
all its input places have enough tokens.
"""
function sufficient_tokens! end

function sufficient_tokens!(enabled_dict::AbstractDict, # transaction id => boolean
                            mark_dict::AbstractDict,    # place id => marking value
                            net::AbstractPnmlNet)
    varsub = NamedTuple() # There are no varibles possible here.
    for tr in transitions(net)
        transition_id = pid(tr)
        if enabled_dict[transition_id]
            # Evaluate preset inscription expressions, compare to mark value.
            # Do all input places of transitions have enough tokens?
            enabled_dict[transition_id] &=
                all(mark_dict[p] >= inscription(arc(net, p, transition_id))(varsub)
                                        for p in preset(net, transition_id))
        end
    end
    return enabled_dict
end

function sufficient_tokens!(enabled_dict::AbstractDict,
                            mark_dict::AbstractDict,
                            net::PnmlNet{<:AbstractHLCore})

   for tr in transitions(net)
        trid = pid(tr)
        empty!(tr.varsubs) #~ clear cached NamedTuple[]
        enabled_dict[trid] || continue
        enabled = enabled_dict[trid]

        #!2025-01-27 JDH moved tr_vars to Transition tr.vars
        # During enabling rule, tr_var_binding_set maps variable to a set of elements.
        tr_var_binding_set = OrderedDict{REFID, Any}()
        #~ marking = PnmlMultiset{B, T}(Multiset{T}(T() => 1)) singleton
        # varsub maps a variable to 1 element of multiset(marking[trid])
        # when enabling/firing transition.
        # Multiset type set from first use

        # Get transition variable substitution from preset arcs.
        # Update enabled and transition
        get_variable_substitutions!(enabled, net, trid, tr_var_binding_set, mark_dict)
        #^--------------------------------------------------------------------------------
        #& XXX variable substitutions fully specified by preset of transition XXX
        #& tr.vars is complete. tr_var_binding_set has valid substitutions (if any exist)
        #^--------------------------------------------------------------------------------

        if enabled
            enabled &= comp_mark_inscription(net, mark_dict, trid,
                                  term(condition(tr)), tr_var_binding_set,
                                  tr.vars, tr.varsubs)
            #! REMEMBER marking multiset element may be a PnmlMultiset.
        end
        enabled_dict[trid] = enabled

    end # for tr
    return enabled_dict
end

"""
Get transition variable substitution from preset arcs.
Updte enabled and transition, tr_var_binding_set.
"""
function get_variable_substitutions!(enabled, net, transaction_id,
                                     tr_var_binding_set, mark_dict)
    for place_id in preset(net, transaction_id)
        ar = arc(net, place_id, transaction_id)
        mark = unwrap_pmset(mark_dict[place_id])
        arc_vars = Multiset(variables(inscription(ar))...) # Count variables.
        # No-variable arcs will be tested for place marking >= inscription & condition.
        isempty(arc_vars) || union!(tr.vars, keys(arc_vars)) # Cache variable REFIDs.

        # Empty per-arc binding.
        arc_var_binding_set = OrderedDict{REFID, Multiset{Symbol}}()

        place_sort = sortref(place(net, place_id))
        enabled &= get_arc_var_binding_set!(arc_var_binding_set, arc_vars,
                                            place_sort, mark, net)
        enabled || break
        enabled &= accum_tr_var_binding_sets!(tr_var_binding_set,
                                              arc_var_binding_set)
        enabled || break
    end # preset arcs
end


function comp_mark_inscription(net, mark_dict, trid, cond_term, tr_var_binding_set, vars, varsubs)
    enabled = true
    for arc in Iterators.filter(a -> (target(a) === trid), values(arcdict(net)))
        place_id = source(arc) # adjacent place
        mark     = mark_dict[place_id]

        # Inscription evaluates to multiset element of sufficent multiplicity.
        # Condition evaluates to `true`
        if isempty(vars) # 0-ary operators
            # This includes the non-HL net types that do not have variables.
            inscription_val = _cvt_inscription_value(pntd(net), arc,
                                            zero_marking(place(net, place_id)),
                                            NamedTuple())
            mi_val = mark >= inscription_val # multiset >= multiset or number >= number
            c_val = eval(toexpr(cond_term, NamedTuple(), net)) #! XXX CACHE
            enabled &= mi_val && c_val
        else
            # Use the transition-level variable substution bindings `tr_var_binding_set`.
            # Iterate over the cartesian product to produce a list of candidate firings.
            # A candidate firing is a NamedTuple variable_id => marking_value of substitutions.
            vtup = tuple(values(tr_var_binding_set)...) # Tuple of Multisets{PnmlMultiset}
            # If an element is a PnmlMultiset it probably is a singleton.
            # Treat as literal value.
            sub1 = tuple((keys.(vtup))...) # substitutions
            vsubiter = Iterators.product(sub1...)
            foreach(vsubiter) do  params
                vsub = namedtuple(tuple(keys(tr_var_binding_set)...), params)
                i_val = _cvt_inscription_value(pntd(net), arc,
                                    zero_marking(place(net, place_id)), vsub)
                mark = unwrap_pmset(mark)
                mi_val = issubset(i_val, mark)
                c_val = eval(toexpr(cond_term, vsub, net)) #! XXX CACHE

                if mi_val && c_val
                    push!(varsubs, vsub)
                else
                    enabled = false # no substitution found
                end
            end
        end
    end
    return enabled
end

"""
    get_arc_var_binding_set!(arc_var_binding_set, arc_vars, placesort, mark, net) -> Bool

Fill `arc_var_binding_set` with an entry for each key in `arc_vars`.
Return `true` if no variables are present or all variables have at least 1 substition.
Indicates that transition is able to fire (enabled fro selection to fire).
"""
function get_arc_var_binding_set!(arc_var_binding_set::AbstractDict,
                                  arc_vars::Multiset, placesort::SortRef, mark, net)
    for v in keys(arc_vars)
        # Each variable must have a non-empty substitution.
        #! variable sorts are never ProductSort. Just one sort.
        # Start with empty substution set for variable.
        # Use multiset as a counter.
        arc_var_binding_set[v] = Multiset{Symbol}()
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
            #! arc_var_binding_set counts possible substitutions in source place's marking.
            # Multiple of same variable in inscription expression means
            # arc_var_binding_set only includes mark elements with multiplicity at least as that large.
            if multiplicity >= arc_vars[v]
                # Variable multiplicity is per-arc, value is shared among arcs.
                if element isa Tuple # mark is a ProductSort.
                    # Select the tuple member(s) matching variable sort.
                    for expr in element
                        if refid(expr) == v_refid
                            push!(arc_var_binding_set[v], expr()) # Add value of expr to set.
                        end
                    end
                else #! element may be a PnmlMultiset
                    push!(arc_var_binding_set[v], element) # Add value to count of substitutions.
                end
            end
        end

        if !isempty(arc_vars) && isempty(arc_var_binding_set[v])
            return false # There are variables and one of them has no substitution.
        end
    end
    return true # No variables or all of them have at least 1 substution.
end
