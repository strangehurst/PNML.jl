AbstractTrees.children(p::Union{PnmlNet,Page}) = pages(p)
AbstractTrees.printnode(io::IO, n::PnmlNet) = print(io, pid(n))
AbstractTrees.printnode(io::IO, p::Page) = print(io, pid(p),
            " ", arc_ids(p),
            " ", place_ids(p), " ",
            " ", transition_ids(p))
AbstractTrees.nodetype(::Union{PnmlNet,Page}) = Page
