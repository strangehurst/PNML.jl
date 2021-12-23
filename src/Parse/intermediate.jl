abstract type Label end
abstract type PnmlObject end
abstract type PnmlNode <: PnmlObject end
abstract type AbstractPnmlTool end

has_xml(tool::PnmlNode) = true
xmlnode(tool::PnmlNode) = tool.xml

has_xml(tool::AbstractPnmlTool) = true
xmlnode(tool::AbstractPnmlTool) = tool.xml

pid(o::PnmlObject) = o.id

onnothing(x,non) = isnothing(x)  ? non : x

###############################################################################
# GRAPHICS
###############################################################################

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
        print(io, "(color: ", f.color,
              ", image: ", f.image,
              ", gradient-color: ", f.gradient_color,
              ", gradient-rotation: ", f.gradient_rotation,
              ")")
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
    print(io,
          "(family: ", f.family,
          ", style: ", f.style,
          ", weight: ", f.weight,
          ", size: ", f.size,
          ", aligh: ", f.align,
          ", rotation: ", f.rotation,
          ", decoration: ", f.decoration,
          ")")
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
          "(color: ", l.color,
          ", style: ", l.style,
          ", shape: ", l.shape,
          ", width: ", l.width,
          ")")
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
    compact = get(io, :compact, false)
    print(io, "(",
          " dimension=", g.dimension,
          " fill=",      g.fill,
          " font=",      g.font,
          " line=",      g.line,
          " offset=",    g.offset,
          " position=",  g.position, ")")
end
    
###############################################################################
# P-T Graphics
###############################################################################

#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

TokenGraphics is a ToolInfo content.
It combines the <tokengraphics> and <tokenposition> elements.
"""
struct TokenGraphics <: AbstractPnmlTool
    positions::Vector{Coordinate}
end

has_xml(::TokenGraphics) = false

compress(a::TokenGraphics) = a

function Base.show(io::IO, tg::TokenGraphics)
    print(io, "positions: ", tg.positions)
end

function Base.show(io::IO, ::MIME"text/plain", tg::TokenGraphics)
    print(io, "TokenGraphics:\n   ", tg)
end

###############################################################################
# PNML TOOLS, NAMES, other bits
###############################################################################

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
    content::Any

    "In case a higher-level wishes to parse the XML."
    xml::Maybe{XMLNode}
end
function DefaultTool(toolname, version; content=nothing, xml=nothing)
    DefaultTool(toolname, version, content, xml)
end

function Base.show(io::IO, t::DefaultTool)
    print(io,
          "name: ", t.toolname,
          "version: ", t.version,
          "content: ", t.content)
end
function Base.show(io::IO, ::MIME"text/plain", t::DefaultTool)
    print(io, "DefaultTool:\n   ", t)
end

#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

PNML Name is for display, possibly in a tool specific way.
"""
struct Name <: Label
    text::String
    graphics::Maybe{Graphics}
    tools::Maybe{Vector{DefaultTool}}
end
has_structure(::Name) = false
structure(::Name) = nothing

Name(name::AbstractString = ""; graphics=nothing, tools=nothing) =
    Name(name, graphics, tools) 

function Base.show(io::IO, n::Name)
    print(io, "'",n.text,"'")
    !isnothing(n.graphics) && print(io, ", has graphics")
    !isnothing(n.tools)    && print(io, ", ", length(n.tools), " tool info")
end
function Base.show(io::IO, ::MIME"text/plain", f::Name)
    print(io, "Name: ", f)
end

###############################################################################
# Common parts
###############################################################################

"""
$(TYPEDEF)
$(TYPEDFIELDS)

PNML Objects and labels share some common infrastructure.
The optional incidental bits are collected here.
"""
struct ObjectCommon
    name::Maybe{Name}
    graphics::Maybe{Graphics}
    tools::Maybe{Vector{DefaultTool}}
    labels::Maybe{Vector{PnmlDict}} #TODO
    xml::Maybe{XMLNode}
end
function ObjectCommon(; name=nothing, graphics=nothing, tools=nothing,
                      labels=nothing, xml=nothing)
    ObjectCommon(name, graphics, tools, labels, xml)
end

ObjectCommon(p::PnmlDict) =
    ObjectCommon(
        get(p, :name, nothing),
        get(p, :graphics, nothing),
        get(p, :tools, nothing),
        get(p, :labels, nothing),
        get(p, :xml, nothing)
    ) 

#TODO SHOW
function Base.show(io::IO, p::ObjectCommon)
    print(io,
          "name: ", p.name,
          ", graphics: ", p.graphics,
          ", tools: ", p.tools,
          ", labels: ", p.labels,)
    # In general, do not display/print the XML. 
    #", xml: ", p.xml)
end
#    print(io, " toolinfo: ", isnothing(p.tools) ?  0 : length(p.tools))
#    print(io, " labels: ", isnothing(p.labels) ?  0 : length(p.labels))
#    isnothing(p.graphics) && print(io, " has graphics" )

###############################################################################
# PNML Nodes
###############################################################################

abstract type Marking <: Label end

#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

PNML PTMarking labels a Place instance.
"""
mutable struct PTMarking{N<:Number} <: Marking
    value::N
    com::ObjectCommon
end

function PTMarking(p::PnmlDict)
    PTMarking(onnothing(p[:value], 0), ObjectCommon(p))
end
convert(::Type{Maybe{PTMarking}}, d::PnmlDict) = PTMarking(d) 
    
function Base.show(io::IO, p::PTMarking)
    print(io, "value: ", p.value, ", ", p.com,)
end
function Base.show(io::IO, ::MIME"text/plain", p::PTMarking)
    print(io, "PTMarking:\n   ", p)
end

#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

PNML HLMarking labels a Place instance.
"""
mutable struct HLMarking <: Marking
    text::Maybe{String}
    structure::Maybe{PnmlDict}
    com::ObjectCommon
end

HLMarking(p::PnmlDict) = HLMarking(p[:text], p[:structure], ObjectCommon(p))
convert(::Type{Maybe{HLMarking}}, d::PnmlDict) = HLMarking(d) 
    
function Base.show(io::IO, p::HLMarking)
    print(io,  "'", p.text, "', ", p.structure, ", ", p.com,)
end
function Base.show(io::IO, ::MIME"text/plain", p::HLMarking)
    print(io, "HLMarking:\n   ", p)
end

#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

PNML Place node.
"""
mutable struct Place <: PnmlNode
    id::Symbol
    marking::Maybe{Marking}
    type::Maybe{PnmlDict}

    com::ObjectCommon
end

Place(p::PnmlDict) = Place(p[:id], p[:marking], p[:type], ObjectCommon(p))

function Base.show(io::IO, p::Place)
    print(io,
          "id: ", p.id,
          ", marking: ", p.marking,
          ", type: ", p.type,
          ", ", p.com,
          )
end
function Base.show(io::IO, ::MIME"text/plain", p::Place)
    print(io, "Place:\n   ", p)
end

#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

PNML Condition labels a Transition instance.
"""
struct Condition <: Label
    text::Maybe{String}
    structure::PnmlDict
    com::ObjectCommon
end

Condition(p::PnmlDict) = Condition(p[:text],
                                   p[:structure] === nothing ? PnmlDict(:tag=>:none) : p[:structure],
                                   ObjectCommon(p))
#convert(::Type{Maybe{Condition}}, d::PnmlDict) = Condition(d) 
    
function Base.show(io::IO, p::Condition)
    print(io,  "'", p.text, "', ", structure, ", ", p.com)
end
function Base.show(io::IO, ::MIME"text/plain", p::Condition)
    print(io, "Condition:\n   ", p)
end

#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

PNML Transition node.
"""
mutable struct Transition <: PnmlNode
    id::Symbol
    condition::Maybe{Condition}

    com::ObjectCommon
end

Transition(d::PnmlDict) = Transition(d[:id], d[:condition], ObjectCommon(d))

function Base.show(io::IO, p::Transition)
    print(io, "id: ", p.id, ", condition: ", p.condition, ", ", p.com,)
end

function Base.show(io::IO, ::MIME"text/plain", p::Transition)
    print(io, "Transition:\n   ", p)
end

#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

PNML RefPlace node.
"""
struct RefPlace <: PnmlNode
    id::Symbol
    ref::Symbol
    com::ObjectCommon
end

RefPlace(d::PnmlDict) = RefPlace(d[:id], d[:ref], ObjectCommon(d))

has_xml(::RefPlace) = false

function Base.show(io::IO, p::RefPlace)
    print(io, "id: ", p.id, ", ref: ", p.ref, ", ", p.com,)
end
function Base.show(io::IO, ::MIME"text/plain", p::RefPlace)
    print(io, "RefPlace:\n   ", p)
end

#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

PNML RefTransition node.
"""
struct RefTransition <: PnmlNode
    id::Symbol
    ref::Symbol
    com::ObjectCommon
end

RefTransition(d::PnmlDict) = RefTransition(d[:id], d[:ref], ObjectCommon(d))

has_xml(::RefTransition) = false

function Base.show(io::IO, p::RefTransition)
    print(io, "id: ", p.id, ", ref: ", p.ref, ", ", p.com,)
end
function Base.show(io::IO, ::MIME"text/plain", p::RefTransition)
    print(io, "RefTransition:\n   ", p)
end

#-------------------<: Inscription
abstract type Inscription <: Label end

#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

PNML PTInscription labels an Arc instance.
"""
mutable struct PTInscription{T<:Number}  <: Inscription
    value::T
    com::ObjectCommon
end

PTInscription(p::PnmlDict) = PTInscription(onnothing(p[:value],1), ObjectCommon(p))
convert(::Type{Maybe{PTInscription}}, d::PnmlDict) = PTInscription(d) 
    
function Base.show(io::IO, p::PTInscription)
    print(io, "value: ", p.value, ", ", p.com,)
end
function Base.show(io::IO, ::MIME"text/plain", p::PTInscription)
    print(io, "PTInscription:\n   ", p)
end

#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

PNML HLInscription labels an Arc instance.
"""
struct HLInscription <: Inscription
    text::Maybe{String}
    structure::Maybe{PnmlDict}
    com::ObjectCommon
end

HLInscription(p::PnmlDict) = HLInscription(p[:text], p[:structure], ObjectCommon(p))
convert(::Type{Maybe{HLInscription}}, d::PnmlDict) = HLInscription(d) 
    
function Base.show(io::IO, ins::HLInscription)
    print(io,   "'", ins.text, "', ", ins.structure, ", ", ins.com,)
end
function Base.show(io::IO, ::MIME"text/plain", ins::HLInscription)
    print(io, "HLInscription:\n   ", ins)
end

#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

PNML Arc connects places and transitions.
"""
mutable struct Arc <: PnmlObject
    id::Symbol
    source::Symbol
    target::Symbol
    inscription::Maybe{Inscription}
    com::ObjectCommon
end

Arc(d::PnmlDict) = Arc(d[:id], d[:source], d[:target], d[:inscription], ObjectCommon(d))

function Base.show(io::IO, arc::Arc)
    print(io, "id: ", arc.id,
          ", source: ", arc.source,
          ", target: ", arc.target,
          ", inscription: ", arc.inscription, ", ", arc.com,)
end
function Base.show(io::IO, ::MIME"text/plain", arc::Arc)
    print(io, "Arc:\n   ", arc)
end

###############################################################################
# Begin section dealing with the top level of a pnml model: nets, pages and 
# labels at equivalent level of the model. Declarations are here because they
# are from tags that are only found as children of <net> and <page> tags.
###############################################################################

#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Declarations are the core of high-level Petri Net.
They define objects/names that are used for conditions, inscriptions, markings.
They are attached to PNML nets and pages.
"""
struct Declaration
    d::PnmlDict 
    com::ObjectCommon
end

Declaration(d::PnmlDict) = Declaration(d, ObjectCommon(d))
convert(::Type{Maybe{Declaration}}, d::PnmlDict) = Declaration(d) 

function Base.show(io::IO, p::Declaration)
    print(io, p.com,)
end
function Base.show(io::IO, ::MIME"text/plain", p::Declaration)
    print(io, "Declaration:\n   ", p)
end

#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Pages contain all places, transitions & arcs. They are for visual presentation.
"""
mutable struct Page <: PnmlObject
    id::Symbol
    places::Vector{Place}
    refPlaces::Vector{RefPlace}
    transitions::Vector{Transition}
    refTransitions::Vector{RefTransition}
    arcs::Vector{Arc}
    declarations::Vector{Declaration}

    subpages::Maybe{Vector{Page}}

    com::ObjectCommon
end

function Page(d::PnmlDict)
    Page(d[:id],
         d[:places], d[:refP],
         d[:trans], d[:refT],
         d[:arcs],
         d[:declarations],
         d[:pages],
         ObjectCommon(d))
end


function Base.show(io::IO, p::Page)
    print(io,
          "id: ", p.id,
          " places: ", p.places,
          " refPlaces: ", p.refPlaces,
          " transitions: ", p.transitions,
          " refTransitions: ", p.refTransitions,
          " arcs: ", p.arcs,
          " declarations: ", p.declarations,
          " subpages: ", p.subpages,
          ", ", p.com,)
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
mutable struct PnmlNet{PNTD<:PnmlType}
    id::Symbol
    type::PNTD
    pages::Vector{Page}
    declarations::Vector{Declaration}
    
    com::ObjectCommon
end

has_xml(tool::PnmlNet) = true
xmlnode(tool::PnmlNet) = tool.xml

function PnmlNet(d::PnmlDict)
    PnmlNet(d[:id], d[:type], d[:pages], d[:declarations],
            ObjectCommon(d)) #[:graphics], d[:tools], d[:labels], d[:xml])
end

function Base.show(io::IO, p::PnmlNet)
    print(io, "id: ", p.id, " type: ", p.type, " name: ", p.com.name)
    print(io, " pages: ", length(p.pages))
    print(io, " declarations: ", isnothing(p.declarations) ?  0 : length(p.declarations))
    print(io, " ", p.com)
    print(io, "\n")
    print(io, p.pages)
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
    nets::Vector{PnmlNet}
    xml::Maybe{XMLNode}
end
Pnml(id::Symbol, net::PnmlNet; xml=nothing) = Pnml(id, [net], xml)
Pnml(id::Symbol, nets::Vector{PnmlNet}; xml=nothing) = Pnml(id, nets, xml)

has_xml(tool::Pnml) = true
xmlnode(tool::Pnml) = tool.xml

function Base.show(io::IO, pnml::Pnml)
    print(io, "id = ", pnml.id, ", ", pnml.nets)
end
function Base.show(io::IO, ::MIME"text/plain", pnml::Pnml)
    print(io, "Pnml:\n   ", pnml)
end

###############################################################################
# 
###############################################################################

