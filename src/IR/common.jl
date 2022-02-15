# common

###############################################################################
# PNML Unclaimed Labels, TOOLS, NAMES, other bits
###############################################################################

#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Unclaimed PNML label wraps a `PnmlDict`` that can be the root of an XML-tree.
Claimed labels will have type defined to make use of the structure 
defined by the pntd schema, see [`Name`](@ref), markings, inscriptions,
etc.

See [`DefaultTool`](@ref) for another PnmlDict wrapper.
"""
struct PnmlLabel <: AbstractLabel
    dict::PnmlDict
    xml::XMLNode
end

function has_text(l::PnmlLabel)
    haskey(l.dict, :text) 
end
function text(l::PnmlLabel)
    l.dict[:text]
end

function has_structure(::PnmlLabel)
    haskey(l.dict, :structure)
end
function structure(::PnmlLabel)
    l.dict[:structure]
end

tag(lab::PnmlLabel) = tag(lab.dict)

has_xml(lab::PnmlLabel) = true
xmlnode(lab::PnmlLabel) = lab.xml

#------------------------------------------------------------------------
# Collection of generic labels
#------------------------------------------------------------------------

has_labels(x::T) where {T<: PnmlObject} = has_labels(x.com)

has_label(x, tagvalue::Symbol) = has_labels(x) ? has_Label(x.com.labels, tagvalue) : false
get_label(x, tagvalue::Symbol) = has_labels(x) ? get_label(x.com.labels, tagvalue) : nothing

###############################################################################
# ToolInfo
###############################################################################

"""
$(TYPEDEF)
$(TYPEDFIELDS)

ToolInfo maps to <toolspecific> tag.
It wraps a vector of well formed elements parsed into [`PnmlLabel`](@ref)s
for use by anything that understands toolname, version toolspecifics.
"""
struct ToolInfo
    toolname::String
    version::String
    infos::Vector{PnmlLabel} #TODO 
    xml::XMLNode
end

function ToolInfo(d::PnmlDict, xml::XMLNode)
    ToolInfo(d[:tool], d[:version], d[:content], xml)
end
convert(::Type{Maybe{ToolInfo}}, d::PnmlDict) = ToolInfo(d)

has_xml(ti::ToolInfo) = true
xmlnode(ti::ToolInfo) = ti.xml

infos(ti::ToolInfo) = ti.infos

#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Tool specific elements can contain any well-formed XML as content.
By default treat the `content` as generic PNML labels.

See [`PnmlLabel`](@ref) for another PnmlDict wrapper.
"""
struct DefaultTool <: AbstractPnmlTool
    info::Vector{PnmlLabel}
end

function DefaultTool(toolname, version; content=nothing, xml=nothing)
    DefaultTool(toolname, version, content, xml)
end

###############################################################################
# P-T Graphics is wrapped in a PnmlLabel
###############################################################################

"""
$(TYPEDEF)
$(TYPEDFIELDS)

TokenGraphics is <toolspecific> content and is wrapped by a [`ToolInfo`](@ref).
It combines the <tokengraphics> and <tokenposition> elements.
"""
struct TokenGraphics{T} <: AbstractPnmlTool
    positions::Vector{T} #was Coordinate}
end

###############################################################################
# Common parts
###############################################################################

"""

$(TYPEDEF)
$(TYPEDFIELDS)
Name is for display, possibly in a tool specific way.
"""
struct Name <: AbstractLabel
    text::String
    graphics::Maybe{Graphics}
    tools::Maybe{Vector{DefaultTool}}
end

Name(name::AbstractString = ""; graphics=nothing, tools=nothing) =
    Name(name, graphics, tools)

#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Common infrastructure shared by PNML objects and labels.
Some optional incidental bits are collected here.
"""
struct ObjectCommon
    name::Maybe{Name}
    graphics::Maybe{Graphics}
    tools::Maybe{Vector{ToolInfo}}
    labels::Maybe{Vector{PnmlLabel}}
end

"""
$(TYPEDSIGNATURES)
Wrap selected fields of `pdict`. Default to `nothing`.
"""
ObjectCommon(pdict::PnmlDict) = ObjectCommon(
    get(pdict, :name, nothing),
    get(pdict, :graphics, nothing),
    get(pdict, :tools, nothing),
    get(pdict, :labels, nothing)
)
#import .PnmlBase.XmlUtils: has_name
has_name(oc::ObjectCommon) = !isnothing(oc.name)
has_xml(oc::ObjectCommon) = false

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
                                   has_labels(oc))
