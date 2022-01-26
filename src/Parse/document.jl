"""
$(TYPEDEF)
$(TYPEDFIELDS)

Corresponds to <pnml> tag.
Wrap the collection of PNML nets from a single XML pnml document.
Adds the IDRegistry to [`PnmlModel`](@ref).
"""
struct Document{N,X}
    nets::N
    xml::X
    reg::IDRegistry
end
#
# Chain of constructors
#
"Construct from valid pnml XML in `s`."
Document(s::AbstractString, reg=IDRegistry()) =
    Document(parse_pnml(root(parsexml(s)); reg), reg)

"Construct from parsed XML in `doc`."
function Document(doc::EzXML.Document)
    reg = PNML.IDRegistry()
    Document(parse_pnml(root(doc); reg), reg)
end

"Construct from `pnml` IR form."
Document(pnml::PnmlModel, reg=IDRegistry()) =
    Document(pnml.nets, xmlnode(pnml), reg)


"""
Build pnml from a string 'str' containing XML.
See [`parse_file`](@ref) and `Document("string")`.

$(TYPEDSIGNATURES)
"""
parse_str(str::AbstractString) = Document(EzXML.parsexml(str))

"""
Build pnml from a fileneame string `fname`.
See [`parse_str`](@ref) and `Document("string")`.

$(TYPEDSIGNATURES)
"""
parse_file(fname::AbstractString) = Document(EzXML.readxml(fname))

Base.summary(doc::Document) = summary(stdout, doc)
function Base.summary(io::IO, doc::Document{N,X}) where {N,X}
    string(typeof(doc), " with ", length(doc.nets), " nets")
end

function Base.show(io::IO, doc::Document{N,X}) where {N,X}
    summary(doc)
    foreach(doc.nets) do net
        println(io, net)
    end
    #TODO Print ID Registry
end

function Base.show(io::IO, ::MIME"text/plain", doc::Document{N,X}) where {N,X}
    print(io, "Document:", doc)
end

"""
Return nets of `doc` matching the given pntd `type` as string or symbol.
See [`pntd_symbol`](@ref), [`pnmltype`](@ref).

---
$(TYPEDSIGNATURES)

$(METHODLIST)
"""
function find_nets end
find_nets(doc::Document, type::AbstractString) = find_nets(doc, pntd_symbol(type))
find_nets(doc::Document, type::Symbol) = find_nets(doc, pnmltype(type))
find_nets(doc::Document, type::T) where T <: PnmlType =
    filter(n->typeof(n.type) <: T, doc.nets)

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
    @debug "append_page!($(pid(l)), $(pid(r)))"
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
