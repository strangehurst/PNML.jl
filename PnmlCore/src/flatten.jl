# Flatten the pages of a Petri Net Markup Language

"""
$(TYPEDSIGNATURES)

Merge page content into the 1st page of each pnml net.

Note that refrence nodes are still present. They can be removed later
with [`deref!`](@ref).
"""
function flatten_pages! end
flatten_pages!(model::PnmlModel) = flatten_pages!.(nets(model))

"""
$(TYPEDSIGNATURES)

Collect keys from all pages and move to first page.
"""
function flatten_pages!(net::PnmlNet)
    #@show "flatten_pages!(net::PnmlNet)"
    # Place content of subpages of 1st page before sibling page's content.
    subpages = firstpage(net).subpages
    if subpages !== nothing
        foldl(flatten_pages!, subpages; init=firstpage(net))
        empty!(subpages)
    end
    # Sibling pages.
    if length(pages(net)) > 1
        foldl(flatten_pages!, pages(net))
        resize!(net.pages, 1)
    end
    deref!(net) # Resolve reference nodes
    return net
end

"After appending `r` to `l`, recursivly flatten `r` into `l`, then empty `r`."
function flatten_pages!(l::Page, r::Page)
    #@show "flatten_pages!($(pid(l)), $(pid(r)))"
    append_page!(l, r)
    if r.subpages !== nothing
        foldl(flatten_pages!, r.subpages; init=l)
    end
    r !== nothing && empty!(r)
    return l
end

"""
Append selected fields of `r` to fields of `l`.
NB: subpages are omitted from `append_page!` See [`flatten_pages!`](@ref).
Names and xml are omitted because they are scalar values, not collections.
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

    l
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
been applied so that everything is on one page (default is first page).

# Axioms
  1) All ids in a network are unique in that they only have one instance in the XML.
  2) A chain of reference Places or Transitions always ends at a Place or Transition.
  3) All ids are valid.
  4) No cycles.
"""
function deref! end

deref!(net::PnmlNet, page_idx=1) = deref!(pages(net)[page_idx])

function deref!(page::Page)
    for arc in arcs(page)
        while arc.source ∈ refplace_ids(page)
            arc.source = deref_place(page, arc.source)
        end
        while arc.target ∈ refplace_ids(page)
            arc.target = deref_place(page, arc.target)
        end
        while arc.source ∈ reftransition_ids(page)
            arc.source = deref_transition(page, arc.source)
        end
        while arc.target ∈ reftransition_ids(page)
            arc.target = deref_transition(page, arc.target)
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
function deref_place end

deref_place(net::PnmlNet, id::Symbol, page_idx=1) = deref_place(pages(net)[page_idx], id)
deref_place(p::Page, id::Symbol) = begin
    #@show "deref_place page $(pid(p)) $id"
    #@show refplaces(p)
    rp = refplace(p, id)
    #@show rp
    if isnothing(rp) # Something is really, really wrong.
        @show reftransition_ids(p)
        @show refplace_ids(p)
        @show place_ids(p)
        @show arc_ids(p)
        @show transition_ids(p)
        error("failed to lookup reference place id $id in page $(pid(p))")
    end
    return rp.ref
end

"""
$(TYPEDSIGNATURES)

Return id of referenced transition.
"""
function deref_transition end

function deref_transition(net::PnmlNet, id::Symbol)
    deref_transition(net.pages[begin], id)
end
function deref_transition(net::PnmlNet, id::Symbol, age_idx)
    deref_transition(net.pages[page_idx], id)
end
function deref_transition(page::Page, id::Symbol)
    #@show "deref_transition page $(pid(page)) id $id"
    #@show refplaces(page)
    rt = reftransition(page, id)
    #@show rt
    if isnothing(rt) # Something is really, really wrong.
        @show refplace_ids(page)
        @show reftransition_ids(page)
        @show place_ids(page)
        @show arc_ids(page)
        @show transition_ids(page)
        @show reftransition_ids(page)
        error("failed to lookup reference transition id $id in page $(pid(page))")
    end
    return rt.ref
end
