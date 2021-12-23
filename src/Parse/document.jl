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
Document(p::Pnml, reg=IDRegistry())           = Document(p.nets, xmlnode(p), reg)
Document(p::PnmlDict, reg=IDRegistry())       = Document(p[:nets], xmlnode(p), reg)

"""
$(TYPEDSIGNATURES)

Return nets of `d` matching the given pntd `type` as string or symbol.
See [`pntd`](@ref).
"""
function find_nets end
find_nets(d::Document, type::AbstractString) = find_nets(d, pntd(type))
find_nets(d::Document, type::Symbol) = find_nets(d, pnmltype(type))
find_nets(d::Document, type::T) where T <: PnmlType = filter(n->typeof(n.type) <: T, d.nets)

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
A well formed PNML XML document has a single root node: <pnml>.
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

#function collect_pages(page::Page)
#    foreach(collect_pages, page.subpages])
#end
#function collect_pages(net::PndmlNet)
#    pages foreach(collect_pages, net.pages)
#    do page
#            ps = get(net, :pages, nothing) # A page may contain other pages
#        end
#    end
#end

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

function append_page!(l::Page, r::Page;
                      keys = [:places, :transitions, :arcs,
                              :refTransitions, :refPlaces, :declarations],
                      comk = [:tools, :labels])
    @show l.id, r.id
    @show propertynames(l)
    foreach(keys) do key
        @show key
        @show getproperty(l,key)
        @show getproperty(r,key)
        append!(getproperty(l,key), getproperty(r,key))
    end
    # Optional fields of Maybe{T}
    foreach(comk) do key
        @show key
        @show getproperty(l.com,key)
        @show getproperty(r.com,key)
        update_maybe!(getproperty(l.com,key), getproperty(r.com,key))
    end

    println("return l")
    l
#    foreach(comk) do key
#        if isnothing(getproperty(l.com,key))
#            if !isnothing(getproperty(r.com,key))
#                setproperty!(l.com,key, getproperty(r.com,key))
#            end
#        else
#            append!(getproperty(l.com,key), getproperty(r.com,key))
#        end
#    end
end

"Collect keys from all pages and move to first page."
function flatten_pages!(net::PnmlNet)
    # Moved the keys into append_page.
    
    # Start with the 1 required Page.
    # Merge 2:end into 1
    # Merge any subpages of 1 into 1.
    @show "Merge 2:end into 1"
    foldl(append_page!, net.pages[:])#, similar(eltype(net.pages[1].key),0))
    #TODO Test that subpage appended/moved to 1.
    @show net.pages
    @show "Merge any subpages of 1 into 1"
    foreach(net.pages[1].subpages) do subpage
        foldl(append_page!, net.pages[1], subpage)
    end
    #TODO Empty unused pages.
    net
end


function flatten_page!(outvec, page::PnmlDict, key)
    # Some of the keys are optional. They may be removed by a compress before flatten.
    if haskey(page, key) && !isnothing(page[key])
        push!.(Ref(outvec), page[key])
        empty!(page[key])
    end
end

function flatten_pages!(net::PnmlDict,
                        keys=[:places, :trans, :arcs,
                              :tools, :labels, :refT, :refP, :declarations])
    for key in keys
        tmp = PnmlDict[]
        # A page may contain other pages. Decend the tree.
        foreach(net.pages) do page
            foreach(page[:pages]) do subpage
                flatten_page!(tmp, subpage, key)
                empty!(subpage)
            end
            flatten_page!(tmp, page, key)
        end
        net.pages[1][key] = tmp
    end
    net
end

function Base.show(io::IO, doc::Document{N,X}) where {N,X}
    println(io, "PNML.Document{$N,$X} ", length(doc.nets), " nets")
    foreach(doc.nets) do net
        println(io, net)
    end
    # ID Registry
end

#---------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------
#
# INTERMEDITE REPRESENTATION moved to intermediate.jl
#
#---------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------

