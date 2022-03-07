"""
Alias for Dict with Symbol as key.

$(TYPEDEF)
"""
const PnmlDict = Dict{Symbol, Any}

"""
Alias for union of type `T` or `nothing`.

$(TYPEDEF)
"""
const Maybe{T} = Union{T, Nothing}

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Wrap `PnmlDict` holding well-formed XML. 
See [`ToolInfo`](@ref) and [`PnmlLabel`](@ref).
"""
struct AnyElement
    dict::PnmlDict
    xml::XMLNode
end

"""
$(TYPEDEF)
Labels are attached to the Petri Net Graph object subtypes. See [`PnmlObject`](@ref).
"""
abstract type AbstractLabel end

# TODO: XMLNode interface
has_xml(::AbstractLabel) = false
xmlnode(::AbstractLabel) = nothing

# TODO: Doc HLLabel interface in manual.
"Return `true` if `label` has text field."
has_text(::AbstractLabel) = false
"Return `text`` field"
text(::AbstractLabel) = nothing

"Return `true` if `label` has a struicture field."
has_structure(::AbstractLabel) = false
"Return `structure` field."
structure(::AbstractLabel) = nothing

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Wrap a `PnmlDict` that may be the root of an XML-tree.

Used for labels that do not have, or we choose not to use, a dedicated parse method.
Claimed labels will have a type defined to make use of the structure 
defined by the pntd schema. See [`Name`](@ref), the only label defined in pnmlcore
and [`HLLabel`](@ref) for similat treatment of "unclaimed" high-level labels.
"""
struct PnmlLabel <: AbstractLabel
    dict::PnmlDict
    xml::XMLNode
end

PnmlLabel(node::XMLNode; kw...) = PnmlLabel(unclaimed_label(node; kw...), node)

tag(label::PnmlLabel) = tag(label.dict)

has_xml(label::PnmlLabel) = true
xmlnode(label::PnmlLabel) = label.xml

"""
$(TYPEDEF)
Objects of a Petri Net Graph are pages, arcs, nodes.
"""
abstract type PnmlObject end

"PnmlObjects are exected to have unique pnml ids."
pid(object::PnmlObject) = object.id

has_labels(x::T) where {T<: PnmlObject} = has_labels(x.com)

has_label(x, tagvalue::Symbol) = has_labels(x) ? has_Label(x.com.labels, tagvalue) : false
get_label(x, tagvalue::Symbol) = has_labels(x) ? get_label(x.com.labels, tagvalue) : nothing

"""
$(TYPEDEF)
Petri Net Graph nodes are places, transitions.
"""
abstract type PnmlNode <: PnmlObject end

has_xml(node::PnmlNode) = true
xmlnode(node::PnmlNode) = node.xml

"""
$(TYPEDEF)

Tool specific objects can be attached to `PnmlObject`s and `AbstractLabel`s subtypes.
"""
abstract type AbstractPnmlTool end #TODO see ToolInfo

has_xml(tool::AbstractPnmlTool) = true
xmlnode(tool::AbstractPnmlTool) = tool.xml
