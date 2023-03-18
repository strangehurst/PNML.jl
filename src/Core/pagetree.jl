AbstractTrees.children(p::Union{PnmlNet,Page}) = get.(Ref(p.pagedict), p.netsets.page_set, nothing)

AbstractTrees.printnode(io::IO, n::PnmlNet) = print(io, pid(n), "::", typeof(n))
AbstractTrees.printnode(io::IO, page::Page) = print(io, pid(page), #"::", typeof(p),
            " arcs ", (collect ∘ values ∘ arc_ids)(page),
            " places ", (collect ∘ values ∘ place_ids)(page), " ",
            " transitions ", (collect ∘ values ∘ transition_ids)(page),
            " refplace ", (collect ∘ values ∘ reftransition_ids)(page),
            " reftransitions ", (collect ∘ values ∘ refplace_ids)(page))

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
