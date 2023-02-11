struct PageTreeNode{T<:PnmlType}
    node::Union{PnmlNet{T},Page{T}} #! Partially specified types.
end

AbstractTrees.children(p::Union{PnmlNet,Page}) = pages(p)
AbstractTrees.printnode(io::IO, n::PnmlNet) = print(io, pid(n), "::", typeof(n))
AbstractTrees.printnode(io::IO, p::Page) = print(io, pid(p), "::", typeof(p),
            " ", arc_ids(p),
            " ", place_ids(p), " ",
            " ", transition_ids(p),
            " ", reftransition_ids(p),
            " ", refplace_ids(p))

# For type stability we need some/all of these.

AbstractTrees.childtype(::Type{PnmlNet{T}}) where {T<:PnmlType} = page_type(Type(T))
AbstractTrees.childtype(::Type{Page{T}}) where {T<:PnmlType} = page_type(Type(T))
#AbstractTrees.childrentype(::Type{PnmlNet{T}}) where {T<:PnmlType} = Vector{page_type(Type(T))}
#AbstractTrees.childrentype(::Type{Page{T}}) where {T<:PnmlType} = Vector{page_type(Type(T))}

#AbstractTrees.NodeType(::Type{<:PnmlNet}) = HasNodeType()
AbstractTrees.nodetype(::Type{PnmlNet{T}}) where {T<:PnmlType} = page_type(Type(T))

#Base.IteratorEltype(::Type{<:TreeIterator{PnmlNet}}) = Base.HasEltype()
#Base.eltype(::Type{<:TreeIterator{PnmlNet{T}}}) where {T<:PnmlType} = page_type(Type(T))

#AbstractTrees.NodeType(::Type{<:Page}) = HasNodeType()
AbstractTrees.nodetype(::Type{Page{T}}) where {T<:PnmlType} = page_type(Type(T))

#Base.IteratorEltype(::Type{<:TreeIterator{Page}}) = Base.HasEltype()
#Base.eltype(::Type{<:TreeIterator{Page{T}}}) where {T<:PnmlType} = page_type(Type(T))
