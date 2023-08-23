# Pages resulting from using keys in set to access pagedict.
AbstractTrees.children(n::PnmlNet) = pages(n)
AbstractTrees.children(p::Page)    = pages(p)

AbstractTrees.printnode(io::IO, n::PnmlNet) = print(io, pid(n), "::", typeof(n))
AbstractTrees.printnode(io::IO, page::Page) = print(io, pid(page),
     " arcs ", foreach(x->string(x, ", "), arc_idset(page)),
     " places ", foreach(x->string(x, ", "), place_idset(page)),
     " transitions ", foreach(x->string(x, ", "), transition_idset(page)),
     " reftransitions ", foreach(x->string(x, ", "), reftransition_idset(page)),
     " refplaces ", foreach(x->string(x, ", "), refplace_idset(page))
     )

# For type stability we need some/all of these.

AbstractTrees.childtype(::Type{PnmlNet{T}}) where {T<:PnmlType} = page_type(T)
AbstractTrees.childtype(::Type{Page{T}}) where {T<:PnmlType} = page_type(T)

AbstractTrees.nodetype(::Type{PnmlNet{T}}) where {T<:PnmlType} = page_type(T)
AbstractTrees.nodetype(::Type{Page{T}}) where {T<:PnmlType} = page_type(T)

#--------------
function pagetree(n::Union{PnmlNet, Page}, inc = 0)
    inc += 1
    print("    "^inc, "pid ", pid(n), ":")
    for i in page_idset(n)
        print(" ", i)
    end
    println()
    for sp in page_idset(n)
        if haskey(pagedict(n), sp)
            @inline pagetree(n.pagedict[sp], inc+1)
        else
            msg = lazy"""id $sp not in page collection with keys: $((collect ∘ keys ∘ pagedict)(n))"""
            throw(ArgumentError(msg))
        end
    end
end
