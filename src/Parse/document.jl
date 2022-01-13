"""
$(TYPEDEF)
$(TYPEDFIELDS)

Wrap the collection of PNML nets from a single XML pnml tree.
Adds the IDRegistry to [`Pnml`](@ref).
Corresponds to <pnml> tag.
"""
struct Document{N,X}
    nets::N
    xml::X
    reg::IDRegistry
end

Document(s::AbstractString, reg=IDRegistry()) = Document(parse_pnml(root(parsexml(s)); reg), reg)
Document(pnml::Pnml, reg=IDRegistry())        = Document(pnml.nets, xmlnode(pnml), reg)
Document(pdict::PnmlDict, reg=IDRegistry())   = Document(pdict[:nets], xmlnode(pdict), reg)


function Base.show(io::IO, doc::Document{N,X}) where {N,X}
    println(io, "PNML.Document{$N,$X} ", length(doc.nets), " nets")
    foreach(doc.nets) do net
        println(io, net)
    end
    #TODO Print ID Registry
end

"""
Return nets of `doc` matching the given pntd `type` as string or symbol.
See [`pntd`](@ref).

---
$(TYPEDSIGNATURES)

$(METHODLIST)
"""
function find_nets end
find_nets(doc::Document, type::AbstractString) = find_nets(doc, pntd(type))
find_nets(doc::Document, type::Symbol) = find_nets(doc, pnmltype(type))
find_nets(doc::Document, type::T) where T <: PnmlType = filter(n->typeof(n.type) <: T, doc.nets)

"""
Return first net contained by `doc`.

$(TYPEDSIGNATURES)
"""
first_net(doc::Document) = first(doc.nets)

"""
Return all `nets` of `doc`.

$(TYPEDSIGNATURES)
"""
nets(doc::Document) = doc.nets
  
"""
Build pnml from a string.

$(TYPEDSIGNATURES)
"""
function parse_str(str)::PNML.Document
    ezdoc = EzXML.parsexml(str)
    parse_doc(ezdoc)
end

"""

Build pnml from a file.

$(TYPEDSIGNATURES)
"""
function parse_file(fname)::PNML.Document
    ezdoc = EzXML.readxml(fname)
    parse_doc(ezdoc)
end

"""
Return a PNML.Document built from an XML Doncuent.
A well formed PNML XML document has a single root node: <pnml>.

$(TYPEDSIGNATURES)
"""
function parse_doc(doc::EzXML.Document)::PNML.Document
    reg = PNML.IDRegistry()
    Document(parse_pnml(root(doc); reg), reg)
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

# NB: subpages are omitted from append_page!
function append_page!(l::Page, r::Page;
                      keys = [:places, :transitions, :arcs,
                              :refTransitions, :refPlaces, :declarations],
                      comk = [:tools, :labels])
    @show "append_page!($(pid(l)), $(pid(r)))"
    foreach(keys) do key
        append!(getproperty(l,key), getproperty(r,key))
    end
    # Optional fields
    foreach(comk) do key
        update_maybe!(getproperty(l.com,key), getproperty(r.com,key))
    end

    l
end

"""
Merge page content into the 1st page of each pnml net.

Note that refrence nodes are still present. They can be removed later
with [`deref!`](@ref).

---
$(TYPEDSIGNATURES)

$(METHODLIST)
"""
function flatten_pages! end

"Flatten each net of PNML document."
function flatten_pages!(doc::PNML.Document)
    foreach(flatten_pages!, nets(doc))
end

"""
Collect keys from all pages and move to first page.

$(TYPEDSIGNATURES)
$(METHODLIST)
"""
function flatten_pages!(net::PnmlNet)
    # Move everything to the 1 required Page.
    @debug "Flatten $(length(net.pages)) page(s) of net $(pid(net))"
    
    # Place content of subpages of 1st page before sibling page's content.
    if !isnothing(net.pages[1].subpages)
        foldl(flatten_pages!, net.pages[1].subpages, init=net.pages[1])
        empty!(net.pages[1].subpages)
    end
    if length(net.pages) > 1
        foldl(flatten_pages!, net.pages[2:end], init=net.pages[1])
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
