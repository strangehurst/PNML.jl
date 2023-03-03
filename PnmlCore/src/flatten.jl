# Flatten the pages of a Petri Net Markup Language

"""
$(TYPEDSIGNATURES)

Merge page content into the 1st page of each pnml net.

Note that refrence nodes are still present. They can be removed later
with [`deref!`](@ref).
"""
function flatten_pages! end
flatten_pages!(model::PnmlModel) = flatten_pages!.(nets(model))

function flatten_pages!(net::PnmlNet)
    if length(net.pagedict) > 1
        # TODO Check for illegal intra-page references?
        # Place content of other pages into 1st page.
        pageids = keys(net.pagedict)
        @show pageids #! debug
        @assert first(pageids) == pid(first(values(net.pagedict)))
        key1,val1 = popfirst!(net.pagedict) # Want the non-mergable bits from the first page.
        @show key1, pageids #! debug
        @assert key1 ∉ pageids

        while !isempty(net.pagedict)
            _, cutval = popfirst!(net.pagedict)
            append_page!(val1, cutval)
        end
        @assert isempty(net.pagedict)
        deref!(val1) # Resolve reference nodes

        net.pagedict[key1] = val1 # Put the one-true-page back in the dictionary.
        @assert !isempty(net.pagedict)
    end
    return net
end

"""
Append selected fields of `r` to fields of `l`.
Some, like Names and xml, are omitted because they are scalar values, not collections.
"""
function append_page!(l::Page, r::Page;
                      keys = [:places, :transitions, :arcs,
                              :refTransitions, :refPlaces, :declaration],
                      comk = [:tools, :labels])
    #@show "append_page!($(pid(l)), $(pid(r)))"
    foreach(keys) do key
        update_maybe!(getproperty(l, key), getproperty(r, key))
    end
    # Optional fields to append.
    foreach(comk) do key
        update_maybe!(getproperty(l.com,key), getproperty(r.com,key))
    end

    return l
end

# Property/Field `key` is to be set or appended.
# Used to merge pages.
# Scalar fields should not be overwritten to preserve first page identity, name.
# Also means that the graphics, gui data is not merged (how would it work?), but one of
# the merged page's field could replace an optional field of the first page.
# Implemented by testing lhs.key for nothing. This works because anything else is assumed
# to be appendable.
function update_maybe!(l, r, key::Symbol)
    if !isnothing(getproperty(r, key))
        if isnothing(getproperty(l, key))
            setproperty!(l, key, getproperty(r, key))
        else
            append!(getproperty(l, key), getproperty(r, key))
        end
    end
end

# See above.
function update_maybe!(l, r)
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

Remove reference nodes from arcs. Expects [`flatten_pages!`](@ref) to have
been applied so that everything is on one page (the first page).

# Axioms
  1) All ids in a network are unique in that they only have one instance in the XML.
  2) A chain of reference Places or Transitions always ends at a Place or Transition.
  3) All ids are valid.
  4) No cycles.
"""
function deref!(page::Page)
    for arc in arcs(page)
        while arc.source ∈ refplace_ids(page)
            s = deref_place(page, arc.source)
            arc.source =  s
        end
        while arc.target ∈ refplace_ids(page)
            t = deref_place(page, arc.target)
            arc.target = t
        end
        while arc.source ∈ reftransition_ids(page)
            s = deref_transition(page, arc.source)
            @set arc.source = s #! Why @set here but not places.
        end
        while arc.target ∈ reftransition_ids(page)
            t = deref_transition(page, arc.target)
            @set arc.target = t
        end
    end
    # Remove reference nodes.
    empty!(page.refPlaces)
    empty!(page.refTransitions)
    page
end

"""
    deref_place(page, id) -> Symbol

Return id of referenced place.
"""
deref_place(p::Page, id::Symbol)::Symbol = begin
    #@show "deref_place page $(pid(p)) $id"
    #@show refplaces(p)
    rp = refplace(p, id)
    #@show rp
    if isnothing(rp) # Something is really, really wrong.
        error("failed to lookup reference place id $id in page $(pid(p))")
        @show refplace_ids(p)
        @show reftransition_ids(p)
        @show place_ids(p)
        @show arc_ids(p)
        @show transition_ids(p)
    end
    return rp.ref
end

"""
$(TYPEDSIGNATURES)

Return id of referenced transition.
"""
function deref_transition(page::Page, id::Symbol)::Symbol
    #@show "deref_transition page $(pid(page)) id $id"
    #@show refplaces(page)
    rt = reftransition(page, id)
    #@show rt
    if isnothing(rt) # Something is really, really wrong.
        error("failed to lookup reference transition id $id in page $(pid(page))")
        @show refplace_ids(page)
        @show reftransition_ids(page)
        @show place_ids(page)
        @show arc_ids(page)
        @show transition_ids(page)
    end
    return rt.ref
end
