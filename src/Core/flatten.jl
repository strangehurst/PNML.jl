# Flatten the pages of a Petri Net Markup Language

"""
$(TYPEDSIGNATURES)

Merge page content into the 1st page of each pnml net.

Note that refrence nodes are still present. They can be removed later
with [`deref!`](@ref).
"""
function flatten_pages! end
flatten_pages!(model::PnmlModel) = flatten_pages!.(nets(model))

function flatten_pages!(net::PnmlNet, trim::Bool = true, verbose::Bool = false)
    CONFIG.verbose &&
        println(lazy"\nflatten_pages! net $(pid(net)) with $(length(net.pagedict)) pages")
    if length(net.pagedict) > 1
        # TODO Check for illegal intra-page references?
        # Place content of other pages into 1st page.
        # Most content is already in the PnmlNetData database.
        pageids = keys(net.pagedict)
        @assert first(pageids) == pid(first(values(net.pagedict)))
        #@show pageids #! debug before pop
        key1,val1 = popfirst!(net.pagedict) # Want the non-mergable bits from the first page.
        #@show key1 pageids #! debug (note the expected change!)
        @assert key1 ∉ pageids

        while !isempty(net.pagedict)
            cutid, cutpage = popfirst!(net.pagedict)
            @assert cutid ∉ pageids
            append_page!(val1, cutpage)
            delete!(page_idset(net), cutid) #! remove from set of page ids owned
        end
        @assert isempty(net.pagedict)

        pagedict(net)[key1] = val1 # Put the one-true-page back in the dictionary.
        push!(page_idset(net), key1) #! add the collected page (netsets updated)
        @assert !isempty(net.pagedict)
        @assert key1 ∈ pageids

        #@show (sort ∘ collect ∘ reftransition_idset)(net)
        #@show (sort ∘ collect ∘ refplace_idset)(net)
        #println("============")
        deref!(net), trim
        #println("============")
        #@show (sort ∘ collect ∘ reftransition_idset)(net)
        #@show (sort ∘ collect ∘ refplace_idset)(net)
    end

    return net
end

"""
Append selected fields of `r` to fields of `l`.
Some, like Names and xml, are omitted because they are scalar values, not collections.

pagedict & netdata (holding the arc and pnml nodes) are per-net data that is not modified here.
netsets hold pnml IDs "owned"
"""
function append_page!(l::Page, r::Page;
                      keys = [:declaration], # netsets
                      comk = [:tools, :labels])

    if CONFIG.verbose
        println("append_page! ", pid(l), " ", pid(r))
        @show netsets(l) netsets(r)
    end

    for k in keys
        _update_maybe!(getproperty(l, k), getproperty(r, k))
    end

    # Merge netsets except for page_idset
    for s in [place_idset, transition_idset, arc_idset, refplace_idset, reftransition_idset]
        union!(s(l), s(r))
    end

    # Optional fields from common to append.
    for key in comk
        _update_maybe!(getproperty(l.com, key), getproperty(r.com, key))
    end

    delete!(page_idset(l), pid(r))

    CONFIG.verbose && println("after append_page! netsets(r) = ", netsets(r))

    #! Verify netsets
    return l
end

# Property/Field `key` is to be set or appended.
# Used to merge pages.
# Scalar fields should not be overwritten to preserve first page identity, name.
# Also means that the graphics, gui data is not merged (how would it work?), but one of
# the merged page's field could replace an optional field of the first page.
# Implemented by testing lhs.key for nothing. This works because anything else is assumed
# to be appendable.
function _update_maybe!(l, r, key::Symbol)
    if !isnothing(getproperty(r, key))
        if isnothing(getproperty(l, key))
            setproperty!(l, key, getproperty(r, key))
        else
            append!(getproperty(l, key), getproperty(r, key))
        end
    end
end

# See above.
function _update_maybe!(l, r)
    if !isnothing(r)
        if isnothing(l)
            l = r
        else
            append!(l, r)
        end
    end
end

"""
$(TYPEDSIGNATURES)

Remove reference nodes from arcs.

Operates on the [`PnmlNetData`](@ref) at the net level.
Expects that the [`PnmlNetKeys`](@ref) of the firstpage will have to be cleaned
as part of [`flatten_pages!`](@ref),

# Axioms
  1) All ids in a network are unique in that they only have one instance in the XML.
  2) A chain of reference Places or Transitions always ends at a Place or Transition.
  3) All ids are valid.
  4) No cycles.
"""
function deref!(net::PnmlNet, trim::Bool = true)
    CONFIG.verbose && @show "deref! net $(pid(net))"
    for id in arc_idset(net)
        arc = PNML.arc(net, id)
        while arc.source ∈ refplace_idset(net)
            arc.source = deref_place(net, arc.source, trim)
        end
        while arc.target ∈ refplace_idset(net)
            arc.target = deref_place(net, arc.target, trim)
        end
        while arc.source ∈ reftransition_idset(net)
            arc.source = deref_transition(net, arc.source, trim)
        end
        while arc.target ∈ reftransition_idset(net)
            arc.target = deref_transition(net, arc.target, trim)
        end
    end
    if trim
        # Remove any reference node idsets from the only remaining page after flattening.
        empty!(refplace_idset(firstpage(net)))
        empty!(reftransition_idset(firstpage(net)))
    end
    return net
end

"""
    deref_place(net, id[, trim] ) -> Symbol

Return id of referenced place. If trim is true (default) the reference is removed.
"""
deref_place(net::PnmlNet, id::Symbol, trim::Bool = true)::Symbol = begin
    CONFIG.verbose && println(lazy"deref_place net $(pid(net)) $id")
    has_refP(net, id) || error(lazy"expected refP $id")
    rp = refplace(net, id)
    if isnothing(rp) # Something is really, really wrong.
        error(lazy"failed to lookup reference place id $id in net $(pid(net))")
    end
    @assert has_place(net, rp.ref)
    if trim #! Not deleting would allow for on-the-fly dereference -- NOT SUPPORTED YET.
        delete!(refplacedict(net), id)
        has_refP(net, id) && error(lazy"did not expect refP $id")
    end
    return rp.ref
end

"""
$(TYPEDSIGNATURES)

Return id of referenced transition. If trim is true (default) the reference is removed.
"""
function deref_transition(net::PnmlNet, id::Symbol, trim::Bool = true)::Symbol
    CONFIG.verbose && println(lazy"deref_transition net $(pid(net)) id $id")
    has_refT(net, id) || error(lazy"expected refT $id")
    rt = reftransition(net, id)
    if isnothing(rt) # Something is really, really wrong.
        error(lazy"failed to lookup reference transition id $id in net $(pid(net))")
    end
    @assert has_transition(net, rt.ref)
    if trim #! Not deleting would allow for on-the-fly dereference -- NOT SUPPORTED YET.
        delete!(reftransitiondict(net), id)
        has_refT(net, id) && error(lazy"did not expect refT $id")
    end
    return rt.ref
end
