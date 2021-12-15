"""
$(TYPEDEF)
$(TYPEDFIELDS)

Wrap the collection of PNML nets from a single XML pnml tree.
Corresponds to <pnml> tag.
"""
struct Document{N,X}
    nets::N
    xml::X
    reg::IDRegistry
end

Document(s::AbstractString, reg=IDRegistry()) =
    Document(parse_pnml(root(parsexml(s)); reg), reg)
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
        println(io, net)
    end
    # ID Registry
end

#---------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------
#
# INTERMEDITE REPRESENTATION
#
#---------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------

abstract type Label end
abstract type PnmlObject end
abstract type PnmlNode <: PnmlObject end
abstract type AbstractPnmlTool end

#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

PNML Graphics Coordinate. 
"""
struct Coordinate{T <: Number}
    x::T
    y::T
end
Coordinate() = Coordinate(0,0)
Coordinate(x) = Coordinate(x, 0)

function Base.show(io::IO, c::Coordinate)
    compact = get(io, :compact, false)
    print(io, "(", c.x, ",", c.y, ")")
end
function Base.show(io::IO, ::MIME"text/plain", c::Coordinate)
    print(io, "Coordinate:\n   ", c)
end

#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

PNML Graphics Fill attributes as strings.
"""
struct Fill
    color::Maybe{String}
    image::Maybe{String}
    gradient_color::Maybe{String}
    gradient_rotation::Maybe{String}
end
function Fill(; color=nothing, image=nothing,
              gradient_color=nothing, gradient_rotation=nothing)
    Fill(color, image, gradient_color, gradient_rotation )
end
function Base.show(io::IO, f::Fill)
    compact = get(io, :compact, false)
    if compact
        print(io, "(", f.color, ",", f.image, ",",
              f.gradient_color, ",", f.gradient_rotation, ")")
    else
        print(io, "color: ", f.color,
              ", image: ", f.image,
              ", gradient-color: ", f.gradient_color,
              ", gradient-rotation: ", f.gradient_rotation)
    end
end
function Base.show(io::IO, ::MIME"text/plain", f::Fill)
    print(io, "Fill:\n   ", f)
end

#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

PNML Font attributes as strings. 
"""
struct Font
    family    ::Maybe{String}
    style     ::Maybe{String}
    weight    ::Maybe{String}
    size      ::Maybe{String}
    align     ::Maybe{String}
    rotation  ::Maybe{String}
    decoration::Maybe{String}
end
function Font(; family=nothing, style=nothing, weight=nothing,
              size=nothing, align=nothing, rotation=nothing, decoration=nothing)
    Font(family, style, weight, size, align, rotation, decoration)
end

function Base.show(io::IO, f::Font)
    print(io, "family: ", f.family,
          ", style: ", f.style,
          ", weight: ", f.weight,
          ", size: ", f.size,
          ", aligh: ", f.align,
          ", rotation: ", f.rotation,
          ", decoration: ", f.decoration)
end
function Base.show(io::IO, ::MIME"text/plain", f::Font)
    print(io, "Font:\n   ", f)
end

#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Line attributes as strings.
"""
struct Line
    color::Maybe{String}
    shape::Maybe{String}
    style::Maybe{String}
    width::Maybe{String}
end
function Line(; color=nothing, shape=nothing, style=nothing, width=nothing)
    Line(color, shape, style, width)
end

function Base.show(io::IO, l::Line)
    print(io,
          ", color: ", l.color,
          ", style: ", l.style,
          ", shape: ", l.shape,
          ", width: ", l.width)
end
function Base.show(io::IO, ::MIME"text/plain", l::Line)
    print(io, "Line:\n   ", l)
end

#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

PNML Graphics elements can be attached to many parts of PNML models.
"""
struct Graphics
    dimension::Maybe{Coordinate}
    fill::Maybe{Fill} 
    font::Maybe{Font}
    line::Maybe{Line} 
    offset::Maybe{Coordinate}
    position::Maybe{Vector{Coordinate}}
end

function Graphics(;dim=nothing, fill=nothing, font=nothing,
                  line=nothing, offset=nothing, position=nothing)
    Graphics(dim, fill, font, line, offset, position)
end

function Base.show(io::IO, g::Graphics)
    @show io
    compact = get(io, :compact, false)
    if compact
        print(io, "Graphics:(",
              " dimension=", g.dimension,
              " fill=",      g.fill,
              " font=",      g.font,
              " line=",      g.line,
              " offset=",    g.offset,
              " position=",  g.position, ")")
    else
        println(io, "Graphics:(")
        println(io, " dimension = ", g.dimension)
        println(io, " fill = ",      g.fill)
        println(io, " font = ",      g.font)
        println(io, " line = ",      g.line)
        println(io, " offset = ",    g.offset)
        println(io, " position = ",  g.position, ")")
    end
end
    
#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

PNML Toolspecific elements can contain any well-formed XML as content.
By default treat the `content` as generic PNML labels.
"""
struct DefaultTool <: AbstractPnmlTool
    toolname::String
    version::String
    "In case a higher-level wishes to parse the XML."
    xml::XMLNode
    content::Any
end

function Base.show(io::IO, ::MIME"text/plain", f::DefaultTool)
    print(io, "DefaultTool:\n   ", f)
end

#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

PNML Name is for display, possibly in a tool specific way.
"""
struct Name <: Label
    value::String
    graphics::Graphics
    tools::Vector{DefaultTool}
end

function Base.show(io::IO, ::MIME"text/plain", f::Name)
    print(io, "Name: ", f)
end

#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

PNML Place node.
"""
struct Place <: PnmlNode
    id::Symbol
    xml::XMLNode
    # marking
end

function Base.show(io::IO, ::MIME"text/plain", p::Place)
    print(io, "Place:\n   ", p)
end

#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

PNML Transition node.
"""
struct Transition <: PnmlNode
    id::Symbol
    xml::XMLNode
    # condition
end

function Base.show(io::IO, ::MIME"text/plain", p::Transition)
    print(io, "Transition:\n   ", p)
end

#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

PNML Arc connects places and transitions.
"""
struct Arc <: PnmlObject
    id::Symbol
    xml::XMLNode
    # inscription
end

function Base.show(io::IO, ::MIME"text/plain", p::Arc)
    print(io, "Arc:\n   ", p)
end

#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Declarations are the core of high-level Petri Net.
They define objects/names that are used for conditions, inscriptions, markings.
They are attached to PNML nets and pages.
"""
struct Declarations 
end

function Base.show(io::IO, ::MIME"text/plain", p::Declarations)
    print(io, "Declarations:\n   ", p)
end

#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Pages contain all places, transitions & arcs. They are for visual presentation.
"""
struct Page <: PnmlObject
    id::Symbol
    places::Vector{Place}
    transitions::Vector{Transition}
    arcs::Vector{Arc}
    name::Maybe{Name}

    subpage::Maybe{Vector{Page}}

    graphics::Maybe{Graphics}
    tools::Maybe{Vector{DefaultTool}}
    labels::Maybe{Vector{Label}}
    xml::Maybe{XMLNode}
end


function Base.show(io::IO, ::MIME"text/plain", p::Page)
    print(io, "Page:\n   ", p)
end

#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Each net in a PNML model has an independent type. 
"""
struct PnmlNet{PNTD<:PnmlType}
    id::Symbol
    type::PNTD
    name::Maybe{Name}

    page::Vector{Page}
    declarations::Vector{Declarations}
    
    graphics::Maybe{Graphics}
    tools::Maybe{Vector{DefaultTool}}
    labels::Maybe{Vector{Label}}
    xml::Maybe{XMLNode}
end


function Base.show(io::IO, ::MIME"text/plain", p::PnmlNet)
    print(io, "PnmlNet:\n   ", p)
end

#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

A PNML model can have multiple net elements.
"""
struct Pnml
    id::Symbol
    net::Vector{PnmlNet}
    xml::Maybe{XMLNode}
end


function Base.show(io::IO, ::MIME"text/plain", pnml::Pnml)
    print(io, "Pnml:\n   ", pnml)
end
