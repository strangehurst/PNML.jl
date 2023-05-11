# TODO Keep pagedict and page_set(s) in sync.
#! Start out in sync, but `flatten!` must keep sync also!
# Vector of pages resulting from using keys in set to access pagedict.
AbstractTrees.children(n::PnmlNet) = collect(pages(n))
AbstractTrees.children(p::Page)    = collect(pages(p))

AbstractTrees.printnode(io::IO, n::PnmlNet) = print(io, pid(n), "::", typeof(n))
AbstractTrees.printnode(io::IO, page::Page) = print(io, pid(page), #"::", typeof(p),
            " arcs ", (collect ∘ values ∘ arc_idset)(page),
            " places ", (collect ∘ values ∘ place_idset)(page), " ",
            " transitions ", (collect ∘ values ∘ transition_idset)(page),
            " reftransitions ", (collect ∘ values ∘ reftransition_idset)(page),
            " refplaces ", (collect ∘ values ∘ refplace_idset)(page))

# For type stability we need some/all of these.

AbstractTrees.childtype(::Type{PnmlNet{T}}) where {T<:PnmlType} = page_type(T) #!
AbstractTrees.childtype(::Type{Page{T}}) where {T<:PnmlType} = page_type(T)

#AbstractTrees.NodeType(::Type{<:PnmlNet}) = HasNodeType()
AbstractTrees.nodetype(::Type{PnmlNet{T}}) where {T<:PnmlType} = page_type(T)

#Base.IteratorEltype(::Type{<:TreeIterator{PnmlNet}}) = Base.HasEltype()
#Base.eltype(::Type{<:TreeIterator{PnmlNet{T}}}) where {T<:PnmlType} = page_type(T)

#AbstractTrees.NodeType(::Type{<:Page}) = HasNodeType()
AbstractTrees.nodetype(::Type{Page{T}}) where {T<:PnmlType} = page_type(T)

#Base.IteratorEltype(::Type{<:TreeIterator{Page}}) = Base.HasEltype()
#Base.eltype(::Type{<:TreeIterator{Page{T}}}) where {T<:PnmlType} = page_type(T)


#--------------


function pagetree(n::Union{PnmlNet, Page}, inc = 0)
    inc += 1
    println("    "^inc, "pid ", pid(n), ": ", (collect ∘ values ∘ page_idset)(n))
    page_keys = (collect ∘ keys ∘ pagedict)(n)
    for sp in page_idset(n)
        if sp in page_keys
            pagetree(n.pagedict[sp], inc+1)
        else
            msg = lazy"""id $sp not in page collection with keys: $page_keys"""
            throw(ArgumentError(msg))
        end
    end
end
