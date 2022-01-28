"Labels are attached to the Petri Net Graph object subtypes. See [`PnmlObject`](@ref)."
abstract type AbstractLabel end
"Objects of a Petri Net Graph are pages, arcs, nodes."
abstract type PnmlObject end
"Petri Net Graph nodes are places, transitions."
abstract type PnmlNode <: PnmlObject end
"Tool specific objects can be attached to `PnmlObject`s and `AbstractLabel`s subtypes."
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
    infos::Vector{PnmlDict}
    xml::Maybe{XMLNode}
end

function ToolInfo(d::PnmlDict)
    ToolInfo(d[:tool], d[:version], d[:content], d[:xml])
end
convert(::Type{Maybe{ToolInfo}}, d::PnmlDict) = ToolInfo(d)

has_xml(::ToolInfo) = true

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

ObjectCommon(pdict::PnmlDict) = ObjectCommon(
    get(pdict, :name, nothing),
    get(pdict, :graphics, nothing),
    get(pdict, :tools, nothing),
    get(pdict, :labels, nothing),
    get(pdict, :xml, nothing)
)

has_name(oc::ObjectCommon) = !isnothing(oc.name)

has_graphics(::Any) = false
has_graphics(oc::ObjectCommon) = !isnothing(oc.graphics)

has_tools(::Any) = false
has_tools(oc::ObjectCommon) = !isnothing(oc.tools)

has_labels(::Any) = false
has_labels(oc::ObjectCommon) = !isnothing(oc.labels)

# Could use introspection on every field if they are all Maybes.
Base.isempty(oc::ObjectCommon) = !(has_name(oc) ||
                                   has_graphics(oc) ||
                                   has_tools(oc) ||
                                   has_labels(oc) ||
                                   has_xml(oc)) #TODO do we care about xml?

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

function PnmlNet(d::PnmlDict)
    PnmlNet(d[:id], d[:type], d[:pages], d[:declarations], ObjectCommon(d))
end

pid(net::PnmlNet) = net.id
has_labels(::PnmlNet) = true
has_xml(::PnmlNet) = true
xmlnode(net::PnmlNet) = net.xml

"Usually the only interesting page."
firstpage(net::PnmlNet) = net.pages[1]

#-------------------
"""
A PNML model can have multiple net elements.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct PnmlModel
    nets::Vector{PnmlNet}
    reg::IDRegistry
    xml::Maybe{XMLNode}
end
PnmlModel(net::PnmlNet) = PnmlModel([net])
PnmlModel(nets::Vector{PnmlNet}) = PnmlModel(nets, IDRegistry(), nothing)
PnmlModel(nets::Vector{PnmlNet}, reg::IDRegistry) = PnmlModel(nets, reg, nothing)

has_xml(tool::PnmlModel) = true
xmlnode(tool::PnmlModel) = tool.xml

"""
Build a PnmlModel from a string 'str' containing XML.

$(TYPEDSIGNATURES)
"""
function parse_str(str::AbstractString)
    reg = IDRegistry()
    parse_pnml(root(EzXML.parsexml(str)); reg)
end

"""
Build a PnmlModel from a file `fname`.

$(TYPEDSIGNATURES)
"""
function parse_file(fname::AbstractString)
    reg = IDRegistry()
    parse_pnml(root(EzXML.readxml(fname)); reg)
end

"""
Return nets matching pntd `type` given as string or symbol.
See [`pntd_symbol`](@ref), [`pnmltype`](@ref).

---
$(TYPEDSIGNATURES)

$(METHODLIST)
"""
function find_nets end
find_nets(model, type::AbstractString) = find_nets(model, pntd_symbol(type))
find_nets(model, type::Symbol) = find_nets(model, pnmltype(type))
find_nets(model, type::T) where T <: PnmlType = filter(n->typeof(n.type) <: T, nets(model))

"""
Return nets matching the pntd `type` given as string or symbol.
See [`pntd_symbol`](@ref), [`pnmltype`](@ref).

---
$(TYPEDSIGNATURES)

$(METHODLIST)
"""
function find_nets end

"""
Return first net contained by `doc`.

$(TYPEDSIGNATURES)
"""
first_net(model) = first(nets(model))

"""
Return all `nets` of `model`.

$(TYPEDSIGNATURES)
"""
nets(model::PnmlModel) = model.nets

###############################################################################
#
###############################################################################
