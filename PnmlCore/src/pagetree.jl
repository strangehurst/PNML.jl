AbstractTrees.children(p::Union{PnmlNet,Page}) = pages(p)
AbstractTrees.printnode(io::IO, p::Union{PnmlNet,Page}) = print(io, pid(p))
AbstractTrees.nodetype(::Union{PnmlNet,Page}) = Page
