# Flatten the pages of a Petri Net Markup Language

"""
$(TYPEDSIGNATURES)

Merge page content into the 1st page of each pnml net.

Note that refrence nodes are still present. They can be removed later
with [`deref!`](@ref).
"""
function flatten_pages! end
flatten_pages!(model::PNML.PnmlModel) = flatten_pages!.(nets(model))

"""
$(TYPEDSIGNATURES)

Collect keys from all pages and move to first page.
"""
function flatten_pages!(net::PnmlNet)
    @debug "Flatten $(length(net.pages)) page(s) of net $(pid(net))"

    # Place content of subpages of 1st page before sibling page's content.
    if !isnothing(firstpage(net).subpages)
        foldl(flatten_pages!, firstpage(net).subpages, init=firstpage(net))
        empty!(firstpage(net).subpages)
    end
    if length(net.pages) > 1
        foldl(flatten_pages!, net.pages[2:end], init=firstpage(net))
        resize!(net.pages, 1)
    end
    net
end

"After appending `r` to `l`, recursivly flatten into `l`, then empty `r`."
function flatten_pages!(l::Page, r::Page)
    @debug "flatten_pages!($(pid(l)), $(pid(r)))"
    append_page!(l, r)
    if !isnothing(r.subpages)
        foldl(flatten_pages!, r.subpages; init=l)
    end
    empty!(r)
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
    @debug "append_page!($(pid(l)), $(pid(r)))"
    foreach(keys) do key
        update_maybe!(getproperty(l, key), getproperty(r, key))
    end
    # Optional fields to append.
    foreach(comk) do key
        update_maybe!(getproperty(l.com,key), getproperty(r.com,key))
    end

    l
end

# 2 Things, each could be nothing.
function update_maybe(l::T, r::T, key::Symbol) where {T <: Maybe{Any}}
    if isnothing(getproperty(l, key))
        if !isnothing(getproperty(r, key))
            setproperty!(l, key, getproperty(r, key))
        end
    else
        append!(getproperty(l, key), getproperty(r, key))
    end
end
function update_maybe!(l::T, r::T) where {T <: Maybe{Any}}
    if isnothing(l)
        if !isnothing(r)
            l = r
        end
    else
        append!(l, r)
    end
end
