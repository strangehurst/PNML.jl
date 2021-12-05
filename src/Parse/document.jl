"""
$(TYPEDEF)

$(TYPEDFIELDS)

Wrap the collection of PNML nets from a single XML tree.
"""
struct Document{N,X}
    nets::N
    xml::X
    reg::IDRegistry
end

Document(s::AbstractString, reg=IDRegistry()) = Document(parse_pnml(root(parsexml(s)); reg), reg)
Document(p::PnmlDict, reg=IDRegistry()) =
    Document{typeof(p[:nets]), typeof(xmlnode(p))}(p[:nets], xmlnode(p), reg)

"""
$(TYPEDSIGNATURES)

Return nets of `d` matching the given pntd `type` as string or symbol.
See [`pntd`](@ref).
"""
function find_nets end
find_nets(d::Document, type::AbstractString) = find_nets(d, pntd(type))
find_nets(d::Document, type::Symbol) = filter(n->n[:type] === type, d.nets)

"""
$(TYPEDSIGNATURES)

Return first net contained by `d`.
"""
first_net(d::Document) = first(d.nets)

"""
$(TYPEDSIGNATURES)

Return all `nets` of `d`.
"""
nets(d::Document) = d.nets
  
"""
$(TYPEDSIGNATURES)

Build pnml from a string.
"""
function parse_str(str)::PNML.Document
    ezdoc = EzXML.parsexml(str)
    parse_doc(ezdoc)
end

"""
$(TYPEDSIGNATURES)
 
Build pnml from a file.
"""
function parse_file(fn)::PNML.Document
    ezdoc = EzXML.readxml(fn)
    parse_doc(ezdoc)
end

"""
$(TYPEDSIGNATURES)

Return a PNML.Document built from an XML Doncuent.
A well formed PNML XML document has a single root node: 'pnml'.
"""
function parse_doc(doc::EzXML.Document)::PNML.Document
    reg = PNML.IDRegistry()
    Document(parse_pnml(root(doc); reg), reg)
end


"""
$(TYPEDSIGNATURES)

Merge page content into the 1st page of each pnml net.
Note that refrence nodes are still present. They can be removed later
with [`deref!`](@ref).
"""
function flatten_pages! end

function flatten_pages!(doc::PNML.Document)
    foreach(flatten_pages!, nets(doc))
end

function collect_pages(net::PnmlDict)
    foreach(net[:pages]) do page
        foreach(page[:pages])
        ps = get(net, :pages, nothing) # A page may contain other pages
    end
end

"Move the elements of 'page[key]' to `outvec`."
function flatten_page!(outvec, page, key)
    # Some of the keys are optional. They may be removed by a compress before flatten.
    if haskey(page, key) && !isnothing(page[key])
        push!.(Ref(outvec), page[key])
        empty!(page[key])
    end
end

"Collect keys from all pages and move to first page."
function flatten_pages!(net::PnmlDict, keys=[:places, :trans, :arcs,
                                             :tools, :labels, :refT, :refP, :declarations])
    @assert tag(net) === :net
    for key in keys
        tmp = PnmlDict[]
        # A page may contain other pages. Decend the tree.
        foreach(net[:pages]) do page
            foreach(page[:pages]) do subpage
                flatten_page!(tmp, subpage, key)
                empty!(subpage)
            end
            flatten_page!(tmp, page, key)
        end
        net[:pages][1][key] = tmp
    end
    net
end

function Base.show(io::IO, doc::Document{N,X}) where {N,X}
    println(io, "PNML.Document{$N,$X} ", length(doc.nets), " nets")
    foreach(doc.nets) do net
        println(io, PNML.compress(net))
    end
    # ID Registry
end
