"Pnml labels."
abstract type AbstractLabel end
"Pnml objects are pages, arcs, nodes."
abstract type PnmlObject end
"Pnml graph nodes are places, transitions."
abstract type PnmlNode <: PnmlObject end
"Tool specific"
abstract type AbstractPnmlTool end

has_xml(node::PnmlNode) = true
xmlnode(node::PnmlNode) = node.xml

has_xml(tool::AbstractPnmlTool) = true
xmlnode(tool::AbstractPnmlTool) = tool.xml

"PnmlObjects are exected to have unique pnml ids."
pid(object::PnmlObject) = object.id

"""
If `x` is `nothing` return `non`, otherwise return `x`.
"""
onnothing(x, non) = isnothing(x) ? non : x

###############################################################################
# GRAPHICS
###############################################################################

"""
PNML Graphics Coordinate. 

$(TYPEDEF)
$(TYPEDFIELDS)
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
PNML Graphics Fill attributes as strings.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct Fill
    color::Maybe{String}
    image::Maybe{String}
    gradient_color::Maybe{String}
    gradient_rotation::Maybe{String}
end
function Fill(; color=nothing, image=nothing, gradient_color=nothing, gradient_rotation=nothing)
    Fill(color, image, gradient_color, gradient_rotation )
end
function Base.show(io::IO, fill::Fill)
    compact = get(io, :compact, false)
    if compact
        print(io, "(", fill.color, ",", fill.image, ",",
              fill.gradient_color, ",", fill.gradient_rotation, ")")
    else
        print(io, "(color: ", fill.color,
              ", image: ", fill.image,
              ", gradient-color: ", fill.gradient_color,
              ", gradient-rotation: ", fill.gradient_rotation,
              ")")
    end
end
function Base.show(io::IO, ::MIME"text/plain", fill::Fill)
    print(io, "Fill:\n   ", fill)
end

#-------------------
"""
PNML Font attributes as strings. 

$(TYPEDEF)
$(TYPEDFIELDS)
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

function Base.show(io::IO, font::Font)
    print(io,
          "(family: ", font.family,
          ", style: ", font.style,
          ", weight: ", font.weight,
          ", size: ", font.size,
          ", aligh: ", font.align,
          ", rotation: ", font.rotation,
          ", decoration: ", font.decoration,
          ")")
end
function Base.show(io::IO, ::MIME"text/plain", font::Font)
    print(io, "Font:\n   ", font)
end

#-------------------
"""
Line attributes as strings.

$(TYPEDEF)
$(TYPEDFIELDS)
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

function Base.show(io::IO, line::Line)
    print(io,
          "(color: ", line.color,
          ", style: ", line.style,
          ", shape: ", line.shape,
          ", width: ", line.width,
          ")")
end
function Base.show(io::IO, ::MIME"text/plain", line::Line)
    print(io, "Line:\n   ", line)
end

#-------------------
"""
PNML Graphics elements can be attached to many parts of PNML models.

$(TYPEDEF)
$(TYPEDFIELDS)
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
          "dimension=", g.dimension,
          " fill=",      g.fill,
          " font=",      g.font,
          " line=",      g.line,
          " offset=",    g.offset,
          " position=",  g.position, ")")
end
    

###############################################################################
# PNML Unclaimed Labels, TOOLS, NAMES, other bits
###############################################################################

#-------------------
"""
PnmlLabel is for unclaimed PNML labels.
It wraps a PnmlDict that can be the root of an XML-tree.

See [`DefaultTool`](@ref) for another PnmlDict wrapper.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct PnmlLabel <: AbstractLabel
    dict::PnmlDict
    #PnmlLabel(d::PnmlDict) = new(d)
end

convert(::Type{Maybe{PnmlLabel}}, d::PnmlDict) = PnmlLabel(d) 

has_structure(::PnmlLabel) = false #TODO Allow HL labels?
structure(::PnmlLabel) = nothing

tag(lab::PnmlLabel) = tag(lab.dict)

function Base.show(io::IO, labelvector::Vector{PnmlLabel})
    foreach(label->println(io,label), labelvector)
end
function Base.show(io::IO, n::PnmlLabel)
    pprint(io, n.dict)
end
function Base.show(io::IO, ::MIME"text/plain", f::PnmlLabel)
    print(io, "PnmlLabel: ", f)
end

#------------------------------------------------------------------------
# Collection of generic labels
#------------------------------------------------------------------------

has_labels(::T) where T<: PnmlObject = true

has_label(x, tagvalue::Symbol) = has_labels(x) ? has_Label(x.com.labels, tagvalue) : false
get_label(x, tagvalue::Symbol) = has_labels(x) ? get_label(x.com.labels, tagvalue) : nothing

###############################################################################
# ToolInfo
###############################################################################

"""
ToolInfo maps to <toolspecific> tag.
It wraps a vector of well formed elements parsed into [`PnmlLabel`](@ref)s
for use by anything that understands toolname, version toolspecifics.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct ToolInfo
    toolname::String
    version::String
    info::Vector{PnmlDict}
    xml::Maybe{XMLNode}
end

function ToolInfo(d::PnmlDict)
    ToolInfo(d[:tool], d[:version], d[:content], d[:xml])
end
convert(::Type{Maybe{ToolInfo}}, d::PnmlDict) = ToolInfo(d) 

has_xml(::ToolInfo) = true

function Base.show(io::IO, toolvector::Vector{ToolInfo})
    foreach(ti->println(io, ti), toolvector)
end

function Base.show(io::IO, ti::ToolInfo)
    print(io,
          "name: ", ti.toolname,
          ", version: ", ti.version,
          ", info: ")
    foreach(d->pprintln(io,d), ti.info) #dict
end

function Base.show(io::IO, ::MIME"text/plain", ti::ToolInfo)
    print(io, "ToolInfo:\n   ", ti)
end

#-------------------
"""
Tool specific elements can contain any well-formed XML as content.
By default treat the `content` as generic PNML labels.

See [`PnmlLabel`](@ref) for another PnmlDict wrapper.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct DefaultTool <: AbstractPnmlTool
    info::Vector{PnmlLabel} #TODO well-formed xml content here: Vector{PnmlLabel}
end
function DefaultTool(toolname, version; content=nothing, xml=nothing)
    DefaultTool(toolname, version, content, xml)
end

function Base.show(io::IO, tool::DefaultTool)
    print(io, "content: (", tool.content, ")")
end
function Base.show(io::IO, ::MIME"text/plain", tool::DefaultTool)
    print(io, "DefaultTool:\n   ", tool)
end

###############################################################################
# P-T Graphics is wrapped in a PnmlLabel
###############################################################################

"""
TokenGraphics is <toolspecific> content and is wrapped by a [`ToolInfo`](@ref).
It combines the <tokengraphics> and <tokenposition> elements.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct TokenGraphics <: AbstractPnmlTool
    positions::Vector{Coordinate}
end

has_xml(::TokenGraphics) = false

function Base.show(io::IO, tg::TokenGraphics)
    print(io, "positions: ", tg.positions)
end

function Base.show(io::IO, ::MIME"text/plain", tg::TokenGraphics)
    print(io, "TokenGraphics:\n   ", tg)
end


###############################################################################
# Common parts
###############################################################################

"""
Name is for display, possibly in a tool specific way.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct Name <: AbstractLabel
    text::String
    graphics::Maybe{Graphics}
    tools::Maybe{Vector{DefaultTool}}
end
has_structure(::Name) = false
structure(::Name) = nothing

Name(name::AbstractString = ""; graphics=nothing, tools=nothing) =
    Name(name, graphics, tools) 

function Base.show(io::IO, name::Name)
    print(io, "'",name.text,"'")
    !isnothing(name.graphics) && print(io, ", has graphics")
    !isnothing(name.tools)    && print(io, ", ", length(name.tools), " tool info")
end
function Base.show(io::IO, ::MIME"text/plain", name::Name)
    print(io, "Name: ", name)
end

#-------------------
"""
Common infrastructure shared by PNML objects and labels.
Some optional incidental bits are collected here.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct ObjectCommon
    name::Maybe{Name}
    graphics::Maybe{Graphics}
    tools::Maybe{Vector{ToolInfo}}
    labels::Maybe{Vector{PnmlLabel}}
    xml::Maybe{XMLNode}
end
function ObjectCommon(; name=nothing, graphics=nothing, tools=nothing,
                      labels=nothing, xml=nothing)
    ObjectCommon(name, graphics, tools, labels, xml)
end

ObjectCommon(pdict::PnmlDict) =
    ObjectCommon(
        get(pdict, :name, nothing),
        get(pdict, :graphics, nothing),
        get(pdict, :tools, nothing),
        get(pdict, :labels, nothing),
        get(pdict, :xml, nothing)
    ) 

Base.summary(io::IO, oc::ObjectCommon) = print(io, summary(oc))
function Base.summary(oc::ObjectCommon)
    string("name: ",
           isnothing(oc.name)  ? nothing : oc.name,
           isnothing(oc.graphics) ? ", no" : ", has", " graphics, ",
           isnothing(oc.tools)  ? 0 : length(oc.tools),  " tools, ",
           isnothing(oc.labels) ? 0 : length(oc.labels), " labels ")
end

function Base.show(io::IO, oc::ObjectCommon)
    !isnothing(oc.graphics) && print(io, ", graphics: ", oc.graphics)
    !isnothing(oc.tools)    && print(io, ", tools: ", oc.tools)
    !isnothing(oc.labels)   && print(io, ", labels: ", oc.labels)
    # In general, do not display/print the XML. 
end

###############################################################################
# PNML Nodes
###############################################################################

"""
$(TYPEDEF)
"""
abstract type Marking <: AbstractLabel end

#-------------------
"""
Labels a Place/Transition pntd Place instance.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
mutable struct PTMarking{N<:Number} <: Marking
    value::N
    com::ObjectCommon
    # PTMarking does not use ObjectCommon.graphics,
    # but rather, TokenGraphics in ObjectCommon.tools.
end

function PTMarking(pdict::PnmlDict)
    PTMarking(onnothing(pdict[:value], 0), ObjectCommon(pdict))
end
convert(::Type{Maybe{PTMarking}}, pdict::PnmlDict) = PTMarking(pdict) 

(ptm::PTMarking)() = ptm.value

function Base.show(io::IO, ptm::PTMarking)
    print(io, "value: ", ptm.value, ", ", ptm.com,)
end
function Base.show(io::IO, ::MIME"text/plain", ptm::PTMarking)
    print(io, "PTMarking:\n   ", ptm)
end

#-------------------
"""
PNML HLMarking labels a Place instance.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
mutable struct HLMarking <: Marking
    text::Maybe{String}
    structure::Maybe{PnmlLabel}
    com::ObjectCommon
end

HLMarking(pdict::PnmlDict) =
    HLMarking(pdict[:text], pdict[:structure], ObjectCommon(pdict))
convert(::Type{Maybe{HLMarking}}, pdict::PnmlDict) = HLMarking(pdict) 

"Evaluate the marking expression."
(hlm::HLMarking)() = @warn "HLMarking functor not implemented"

function Base.show(io::IO, hlm::HLMarking)
    print(io,  "'", hlm.text, "', ", hlm.structure, ", ", hlm.com,)
end
function Base.show(io::IO, ::MIME"text/plain", hlm::HLMarking)
    print(io, "HLMarking:\n   ", hlm)
end

#-------------------
"""
PNML Place node.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
mutable struct Place <: PnmlNode
    id::Symbol
    marking::Maybe{Marking}
    type::Maybe{PnmlLabel}

    com::ObjectCommon
end

Place(pdict::PnmlDict) =
    Place(pdict[:id], pdict[:marking], pdict[:type], ObjectCommon(pdict))

function Base.show(io::IO, placevector::Vector{Place})
    isempty(placevector) && return
    foreach(place->println(io, place), @view placevector[begin:end-1])
    print(io, placevector[end])
end
function Base.show(io::IO, place::Place)
    print(io,
          "id: ", place.id,
          ", ", summary(place.com),
          ", marking: ", place.marking,
          ", type: ", place.type, ", ",
          place.com)
end
function Base.show(io::IO, ::MIME"text/plain", place::Place)
    print(io, "Place:\n   ", place)
end

#-------------------
"""
PNML Condition labels a Transition instance.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct Condition <: AbstractLabel
    text::Maybe{String}
    structure::Maybe{PnmlLabel}
    com::ObjectCommon
end

Condition(pdict::PnmlDict) = Condition(pdict[:text],
                                       pdict[:structure],
                                       ObjectCommon(pdict))
#convert(::Type{Maybe{Condition}}, d::PnmlDict) = Condition(d) 
    
function Base.show(io::IO, cond::Condition)
    print(io,  "'", cond.text, "', ", cond.structure, ", ",  cond.com)
end
function Base.show(io::IO, ::MIME"text/plain", cond::Condition)
    print(io, "Condition:\n   ", cond)
end

#-------------------
"""
PNML Transition node.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
mutable struct Transition <: PnmlNode
    id::Symbol
    condition::Maybe{Condition}

    com::ObjectCommon
end

Transition(pdict::PnmlDict) =
    Transition(pdict[:id], pdict[:condition], ObjectCommon(pdict))

function Base.show(io::IO, trans::Transition)
    print(io, "id: ", trans.id, ", condition: ", trans.condition, ", ", trans.com,)
end

function Base.show(io::IO, ::MIME"text/plain", trans::Transition)
    print(io, "Transition:\n   ", trans)
end

#-------------------
"""
PNML RefPlace node.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct RefPlace <: PnmlNode
    id::Symbol
    ref::Symbol
    com::ObjectCommon
end

RefPlace(pdict::PnmlDict) = RefPlace(pdict[:id], pdict[:ref], ObjectCommon(pdict))

has_xml(::RefPlace) = false

function Base.show(io::IO, refp::RefPlace)
    print(io, "id: ", refp.id, ", ref: ", refp.ref, ", ", refp.com,)
end
function Base.show(io::IO, ::MIME"text/plain", refp::RefPlace)
    print(io, "RefPlace:\n   ", refp)
end

#-------------------
"""
PNML RefTransition node.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct RefTransition <: PnmlNode
    id::Symbol
    ref::Symbol
    com::ObjectCommon
end

RefTransition(pdict::PnmlDict) =
    RefTransition(pdict[:id], pdict[:ref], ObjectCommon(pdict))

has_xml(::RefTransition) = false

function Base.show(io::IO, reft::RefTransition)
    print(io, "id: ", reft.id, ", ref: ", reft.ref, ", ",  reft.com,)
end
function Base.show(io::IO, ::MIME"text/plain", reft::RefTransition)
    print(io, "RefTransition:\n   ", reft)
end

#-------------------<: Inscription
abstract type Inscription <: AbstractLabel end

#-------------------
"""
PTInscription labels an Arc instance.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
mutable struct PTInscription{T<:Number}  <: Inscription
    value::T
    com::ObjectCommon
end

PTInscription(pdict::PnmlDict) =
    PTInscription(onnothing(pdict[:value],1), ObjectCommon(pdict))
convert(::Type{Maybe{PTInscription}}, pdict::PnmlDict) = PTInscription(pdict) 
    
function Base.show(io::IO, ins::PTInscription)
    print(io, "value: ", ins.value, ", ", ins.com,)
end
function Base.show(io::IO, ::MIME"text/plain", ins::PTInscription)
    print(io, "PTInscription:\n   ", ins)
end

#-------------------
"""
HLInscription labels an Arc instance.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct HLInscription <: Inscription
    text::Maybe{String}
    structure::Maybe{PnmlLabel}
    com::ObjectCommon
end

HLInscription(pdict::PnmlDict) =
    HLInscription(pdict[:text], pdict[:structure], ObjectCommon(pdict))
convert(::Type{Maybe{HLInscription}}, pdict::PnmlDict) = HLInscription(pdict) 
    
function Base.show(io::IO, ins::HLInscription)
    print(io,   "'", ins.text, "', ", ins.structure, ", ", ins.com,)
end
function Base.show(io::IO, ::MIME"text/plain", ins::HLInscription)
    print(io, "HLInscription:\n   ", ins)
end

#-------------------
"""
Arc connects places and transitions.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
mutable struct Arc <: PnmlObject
    id::Symbol
    source::Symbol
    target::Symbol
    inscription::Maybe{Inscription} #TODO Abstract, could br a Union.
    com::ObjectCommon
end

Arc(pdict::PnmlDict) =
    Arc(pdict[:id], pdict[:source], pdict[:target], pdict[:inscription], ObjectCommon(pdict))

function Base.show(io::IO, arc::Arc)
    print(io, "(id: ", arc.id,
          ", source: ", arc.source,
          ", target: ", arc.target,
          ", inscription: ", arc.inscription,
          arc.com,
          ")")
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
Declarations are the core of high-level Petri Net.
They define objects/names that are used for conditions, inscriptions, markings.
They are attached to PNML nets and pages.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct Declaration
    d::PnmlLabel # TODO what do declarations contain? Land of Symbolics.jl.
    com::ObjectCommon
end

Declaration(pdict::PnmlDict) = Declaration(PnmlLabel(pdict), ObjectCommon(pdict))
convert(::Type{Maybe{Declaration}}, pdict::PnmlDict) = Declaration(pdict) 

function Base.show(io::IO, declarations::Vector{Declaration})
    isempty(declarations) && return
    foreach(declare->println(io, declare), @view declarations[begin:end-1])
    print(io, declarations[end])
end
function Base.show(io::IO, declare::Declaration)
    print(io, declare.d, ", ", declare.com,)
end
function Base.show(io::IO, ::MIME"text/plain", declare::Declaration)
    print(io, "Declaration:\n   ", declare)
end

#-------------------
"""
Contain all places, transitions & arcs. They are for visual presentation.
There must be at least 1 Page for a valid pnml model.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
mutable struct Page{PNTD<:PnmlType} <: PnmlObject
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

function Page(d::PnmlDict, pntd = PnmlCore())
    Page{typeof(pntd)}(
        d[:id],
        d[:places], d[:refP],
        d[:trans], d[:refT],
        d[:arcs],
        d[:declarations],
        d[:pages],
        ObjectCommon(d))
end

function Base.empty!(page::Page)
    empty!(page.places)
    empty!(page.refPlaces)
    empty!(page.transitions)
    empty!(page.refTransitions)
    empty!(page.arcs)
    empty!(page.declarations)
    !isnothing(page.subpages) && empty!(page.subpages)
end

function Base.summary(io::IO, page::Page) print(io, summary(page)) end
function Base.summary( page::Page)
    string("PNML Page Id: ", page.id, ", ",
           length(page.places), " places ",
           length(page.refPlaces), " refPlaces ",
           length(page.transitions), " transitions ",
           length(page.refTransitions), " refTransitions ",
           length(page.arcs), " arcs ",
           length(page.declarations), " declarations ",
           length(page.subpages), " subpages ",
           summary(page.com)
           )
end

function Base.show(io::IO, page::Page)
    println(io, summary(page))
    println(io, "places: ", page.places)
    println(io, "refPlaces: ", page.refPlaces)
    println(io, "transitions: ", page.transitions)
    println(io, "refTransitions: ", page.refTransitions)
    println(io, "arcs: ", page.arcs)
    println(io, "declarations: ", page.declarations)
    println(io, "subpages: ", page.subpages)
    println(io, page.com)
end

Base.show(io::IO, pages::Vector{Page}) = foreach(page->println(io, page), pages)

function Base.show(io::IO, ::MIME"text/plain", p::Page)
    print(io, "Page:\n   ", p)
end

#-------------------
"""
Each net in a PNML model has an independent type. 

$(TYPEDEF)
$(TYPEDFIELDS)
"""
mutable struct PnmlNet{PNTD<:PnmlType}
    id::Symbol
    type::PNTD
    pages::Vector{Page}
    declarations::Vector{Declaration}
    
    com::ObjectCommon
end

function PnmlNet(pdict::PnmlDict)
    PnmlNet(pdict[:id], pdict[:type], pdict[:pages], pdict[:declarations],
            ObjectCommon(pdict)) 
end

pid(net::PnmlNet) = net.id
has_labels(::PnmlNet) = true
has_xml(::PnmlNet) = true
xmlnode(net::PnmlNet) = net.xml

"Usually the only interesting page."
firstpage(net::PnmlNet) = net.pages[1]

Base.summary(io::IO, net::PnmlNet) = print(io, summary(net))
function Base.summary(net::PnmlNet)
    string( typeof(net), " id ", net.id, " type ", net.type, ", ",
            length(net.pages), " pages ",
            length(net.declarations), " declarations ",
            summary(net.com))
end

function Base.show(io::IO, net::PnmlNet)
    println(io, summary(net))
    println(io, net.com)
    println(io, net.declarations)
    println(io, net.pages)
end

function Base.show(io::IO, ::MIME"text/plain", net::PnmlNet)
    print(io, "PnmlNet:\n   ", net)
end

#-------------------
"""
A PNML model can have multiple net elements.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct Pnml
    nets::Vector{PnmlNet}
    xml::Maybe{XMLNode}
end
Pnml(net::PnmlNet; xml=nothing) = Pnml(id, [net], xml)
Pnml(nets::Vector{PnmlNet}; xml=nothing) = Pnml(id, nets, xml)

has_xml(tool::Pnml) = true
xmlnode(tool::Pnml) = tool.xml

Base.summary(io::IO, pnml::Pnml) = print(io, summary(pnml))
function Base.summary(pnml::Pnml)
    l = length(pnml.nets)
    return "PNML model with $l nets"   
end

function Base.show(io::IO, pnml::Pnml)
    println(io, summary(pnml))
    println(io, pnml.nets)
end
function Base.show(io::IO, ::MIME"text/plain", pnml::Pnml)
    print(io, "Pnml:\n   ", pnml)
end

###############################################################################
# 
###############################################################################

