# Flatten the pages of a Petri Net Markup Language
# TODO Check for illegal intra-page references? WHERE?

"""
    flatten_pages!(net::PnmlNet[; options])

Merge page content into the 1st page of the net.

Options
  - trim::Bool Remove refrence nodes (default `true`). See [`deref!`](@ref).
  - verbose::Bool Print breadcrumbs See [`CONFIG`](@ref).
"""
function flatten_pages! end

# Most content is already in the PnmlNetData database so mostly involves shuffling keys
function flatten_pages!(net::PnmlNet; trim::Bool = true, verbose::Bool = CONFIG.verbose)
    netid = pid(net)
    verbose && println("flatten_pages! net $netid with $(length(pagedict(net))) pages")
    if length(pagedict(net)) > 1 # Place content of other pages into 1st page.
        pageids = keys(pagedict(net))
        verbose && @show(pageids)

        # Choose the surviving page from those owned directly by net.
        key1 = first(page_idset(net))
        val1 = pagedict(net)[key1]
        verbose && println("delete!(pagedict(net), $key1)")
        delete!(pagedict(net), key1)
        @assert key1 ∉ pageids # Note the coupling of pageids and net.pagedict.

        verbose && println("pageids now = $(keys(pagedict(net)))")

        while !isempty(pagedict(net))
            cutid, cutpage = popfirst!(pagedict(net))
            @assert cutid ∉ pageids
            append_page!(val1, cutpage; verbose)
            delete!(page_idset(net), cutid) # Remove from set of page ids owned by net.
        end
        @assert isempty(pagedict(net))

        # Put the one-true-page back in the dictionary.
        pagedict(net)[key1] = val1

        @assert key1 ∈ page_idset(net) # We never removed the one-true key.
        @assert key1 ∈ pageids # Note the coupling of pageids and net.pagedict.
        if verbose
            println("after flatten to one page")
            @show(pagedict(net))
        end

        deref!(net; trim, verbose)

        if verbose
            println("\nafter deref!")
            @show(pagedict(net))
        end
    end
    return nothing
end

"Verify a `PnmlNet` after it has been flattened or is otherwise expected to be a single-page net."
function post_flatten_verify(net::PnmlNet;
                          trim::Bool = true,
                          verbose::Bool = CONFIG.verbose)
    verbose && @info "post_flatten_verify"
    errors = String[]

    npages(net) == 1 || push!(errors, "wrong pagedict length: expected 1 found $(npages(net)))")
    length(page_idset(net)) == 1 || push!(errors, "wrong page_idset length: expected 1 found $(length(page_idset(net)))")

    nrefplaces(net) == 0 || push!(errors, "refplacedict not empty")
    isempty(refplace_idset(net)) || push!(errors, "refplace_idset not empty")

    nreftransitions(net) == 0 || push!(errors, "reftransitiondict not empty")
    isempty(reftransition_idset(net)) || push!(errors, "reftransition_idset not empty")

    isempty(errors) ||
        error("net $(pid(net)) post flatten errors: ", join(errors, ",\n "))
    return true
end

"""
Append selected fields of `r` to fields of `l`.
Some, like Names and xml, are omitted because they are scalar values, not collections.

pagedict & netdata (holding the arc and pnml nodes) are per-net data that is not modified here.
netsets hold pnml IDs "owned"
"""
function append_page!(lpage::Page, rpage::Page;
            # Moved declarations to per-net DeclDict 2024-03-22.
            keys = (:tools, :labels), # non-idset and non-dict fields of page to merge
            idsets = (place_idset, transition_idset, arc_idset, refplace_idset, reftransition_idset,),
            verbose::Bool = CONFIG.verbose            )

    if verbose
        println("append_page! ", pid(lpage), " ", pid(rpage))
        @show netsets(lpage) netsets(rpage)
        #@show lpage rpage
    end

    for k in keys
        _update_maybe!(getproperty(lpage, k), getproperty(rpage, k))
    end

    for s in idsets # except for page_idset
        union!(s(lpage), s(rpage)) #TODO type assert
    end
    verbose && println("delete!(page_idset(lpage), $(pid(rpage)))")
    delete!(page_idset(lpage), pid(rpage))
    @assert pid(rpage) ∉ page_idset(lpage)
    if verbose
        println("after append_page!")
        @show netsets(lpage) #~ ensure empty page garbage collected?
    end
    #! TODO Verify netsets
    return lpage
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
  2) A chain of reference Places (or Transitions) always ends at a Place (or Transition).
  3) All ids are valid.
  4) No cycles.
"""
function deref!(net::PnmlNet; trim::Bool = true, verbose::Bool = CONFIG.verbose)
    if verbose
        println("deref!")
        @show nrefplaces(net) nreftransitions(net) narcs(net)
        @show refplaces(net) reftransitions(net) arcs(net)
        @show isempty(refplaces(net)) isempty(reftransitions(net)) isempty(arcs(net))
        println()
    end
    if isempty(refplaces(net)) && isempty(nreftransitions(net))
        verbose && println("no references")
        return nothing
    end
    isempty(arcdict(net)) && error("no arcs")

    for arc in arcs(net)
        verbose && @show(arc)
        while arc.source[] ∈ refplace_idset(net)
            arc.source[] = deref_place(net, arc.source[]; trim, verbose)
        end
        while arc.target[] ∈ refplace_idset(net)
            arc.target[] = deref_place(net, arc.target[]; trim, verbose)
        end
        while arc.source[] ∈ reftransition_idset(net)
            arc.source[] = deref_transition(net, arc.source[]; trim, verbose)
        end
        while arc.target[] ∈ reftransition_idset(net)
            arc.target[] = deref_transition(net, arc.target[]; trim, verbose)
        end
    end
    if trim
        # Remove any reference node idsets from the only remaining page after flattening.
        empty!(refplace_idset(firstpage(net)))
        empty!(reftransition_idset(firstpage(net)))
        # And the nodes themselves.
        empty!(refplacedict(net))
        empty!(reftransitiondict(net))
    end
    return nothing
end

"""
    deref_place(net, id[], trim::Bool] ) -> Symbol

Return id of referenced place. If trim is `true` (default) the reference is removed.
"""
function deref_place(net::PnmlNet, id::Symbol; trim::Bool = true, verbose::Bool = CONFIG.verbose)::Symbol
    netid = pid(net)
    has_refplace(net, id) ||
        throw(ArgumentError("expected refplace $id to be found in net $netid"))

    rp = refplace(net, id)
    isnothing(rp) && # Something is really, really wrong.
        throw(ArgumentError("failed to lookup reference place id $id in net $netid)"))
    has_place(net, refid(rp)) || has_refplace(net, refid(rp)) ||
        throw(ArgumentError("$(refid(rp)) is not a place or reference place"))

    if trim
        delete!(refplacedict(net), id)
        has_refplace(net, id) &&
            error("did not expect refplace $id in net $netid after delete")
    end
    verbose && println("net $netid dereference $id to $rp: $(refid(rp))")
    return refid(rp)
end

"""
    deref_transition(net, id[, trim::Bool] ) -> Symbol

Return id of referenced transition. If trim is `true` (default) the reference is removed.
"""
function deref_transition(net::PnmlNet, id::Symbol; trim::Bool = true, verbose::Bool = CONFIG.verbose)::Symbol
    netid = pid(net)
    has_reftransition(net, id) || (throw ∘ ArgumentError)("expected reftransition $id in net $netid")
    rt = reftransition(net, id)
    isnothing(rt) && # Something is really, really wrong.
        (throw ∘ ArgumentError)("failed to lookup reference transition id $id in net $netid")
    has_transition(net, refid(rt)) || has_reftransition(net, refid(rt)) ||
        (throw ∘ ArgumentError)("$(refid(rt)) is not a transition or reference transition in net $netid")
    if trim
        delete!(reftransitiondict(net), id)
        has_reftransition(net, id) &&
            error("did not expect reftransition $id in net $netid after delete")
    end
    verbose && println("net $netid dereference $id to $rt: $(refid(rt))")
    return refid(rt)
end
