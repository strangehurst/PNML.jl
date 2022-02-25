###############################################################################
# PNML Unclaimed Labels, TOOLS, NAMES, other bits
###############################################################################

#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Wrap a `PnmlDict` that can be the root of an XML-tree.

Used for labels that do not have, or we choose not to use, a dedicated parse method.
Claimed labels will have a type defined to make use of the structure 
defined by the pntd schema. See [`Name`](@ref), the only label defined in pnmlcore.
"""
struct PnmlLabel <: AbstractLabel
    dict::PnmlDict
    xml::XMLNode
end

PnmlLabel(node::XMLNode; kw...) = 
    PnmlLabel(unclaimed_element(node; kw...), node)

"""
Return `true` if the label has a `text`` element.
"""
function has_text(label::AbstractLabel)
    haskey(label.dict, :text) 
end

"Return `text` element."
function text(label::AbstractLabel)
    label.dict[:text]
end

"""
Return `true` if the label has a `structure`` element.
"""
function has_structure(label::AbstractLabel)
    haskey(label.dict, :structure)
end

"Return `structure` element."
function structure(label::AbstractLabel)
    label.dict[:structure]
end

tag(label::PnmlLabel) = tag(label.dict)

has_xml(label::PnmlLabel) = true
xmlnode(label::PnmlLabel) = label.xml

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

ToolInfo holds a <toolspecific> tag.

It wraps a vector of well formed elements parsed into [`PnmlLabel`](@ref)s
for use by anything that understands toolname, version toolspecifics.
"""
struct ToolInfo
    toolname::String
    version::String
    infos::Vector{PnmlLabel} #TODO specialize?
    xml::XMLNode
end

function ToolInfo(d::PnmlDict, xml::XMLNode)
    ToolInfo(d[:tool], d[:version], d[:content], xml)
end
convert(::Type{Maybe{ToolInfo}}, d::PnmlDict) = ToolInfo(d)

has_xml(ti::ToolInfo) = true
xmlnode(ti::ToolInfo) = ti.xml

infos(ti::ToolInfo) = ti.infos

###############################################################################
# P-T Graphics is wrapped in a PnmlLabel
###############################################################################

"""
$(TYPEDEF)
$(TYPEDFIELDS)

TokenGraphics is <toolspecific> content and is wrapped by a [`ToolInfo`](@ref).
It combines the <tokengraphics> and <tokenposition> elements.
"""
struct TokenGraphics <: AbstractPnmlTool
    positions::Vector{Coordinate} #TODO: uses abstract type
end

# Empty TokenGraphics is allowed in spec.
TokenGraphics() = TokenGraphics(Coordinate[])
#TokenGraphics(v::Vector{Coordinate}) = 

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
    tools::Maybe{Vector{ToolInfo}}
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

"Return `true` if has a `name` element."
has_name(oc::ObjectCommon) = !isnothing(oc.name)
has_xml(oc::ObjectCommon) = false

"Return `true` if has a `graphics` element."
has_graphics(::Any) = false
has_graphics(oc::ObjectCommon) = !isnothing(oc.graphics)

"Return `true` if has a `tools` element."
has_tools(::Any) = false
has_tools(oc::ObjectCommon) = !isnothing(oc.tools)

"Return `true` if there is a `labels` element."
has_labels(::Any) = false
has_labels(oc::ObjectCommon) = !isnothing(oc.labels)

# Could use introspection on every field if they are all Maybes.
Base.isempty(oc::ObjectCommon) = !(has_name(oc) ||
                                   has_graphics(oc) ||
                                   has_tools(oc) ||
                                   has_labels(oc))

function Base.empty!(oc::ObjectCommon)
    has_name(oc) && empty!(oc.name)
    has_graphics(oc) && empty!(oc.graphics)
    has_tools(oc) && empty!(oc.tools)
    has_labels(oc) && empty!(oc.labels)
end
