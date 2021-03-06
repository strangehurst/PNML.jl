"""
Alias for union of type `T` or `nothing`.

$(TYPEDEF)
"""
const Maybe{T} = Union{T, Nothing}

"""
Alias for Dict with Symbol as key.

$(TYPEDEF)
"""
const PnmlDict = Dict{Symbol, Any}

pid(pdict::PnmlDict)::Symbol = pdict[:id]
tag(pdict::PnmlDict)::Symbol = pdict[:tag]


#has_xml(pdict::PnmlDict) = false
xmlnode(pdict::PnmlDict) = pdict[:xml]

has_labels(pdict::PnmlDict) = haskey(pdict, :labels)
has_label(d::PnmlDict, tagvalue::Symbol) = if has_labels(d)
    has_label(labels(d), tagvalue)
else
    false
end

labels(pdict::PnmlDict) = pdict[:labels]

get_label(d::PnmlDict, tagvalue::Symbol) = has_labels(d) ? get_label(labels(d), tagvalue) : nothing
get_labels(d::PnmlDict, tagvalue::Symbol) = get_labels(labels(d), tagvalue)

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Wrap `PnmlDict` holding well-formed XML.
See [`ToolInfo`](@ref) and [`PnmlLabel`](@ref).
"""
@auto_hash_equals struct AnyElement
    tag::Symbol
    dict::PnmlDict
    xml::XMLNode
end

AnyElement(p::Pair{Symbol,PnmlDict}, xml::XMLNode) = AnyElement(p.first, p.second, xml)

tag(a::AnyElement) = a.tag
dict(a::AnyElement) = a.dict
xmlnode(a::AnyElement) = a.xml

"""
$(TYPEDEF)
Labels are attached to the Petri Net Graph object subtypes. See [`PnmlObject`](@ref).
"""
abstract type AbstractLabel end

xmlnode(::AbstractLabel) = nothing

# TODO: Doc HLLabel interface in manual.
"Return `true` if label has `text` field."
has_text(l::L) where {L <: AbstractLabel} = hasproperty(l, :text) && !isnothing(l.text)
"Return `text` field"
text(l::L) where {L <: AbstractLabel} = l.text

"Return `true` if label has a `structure` field."
has_structure(l::L) where {L <: AbstractLabel} = hasproperty(l, :structure) && !isnothing(l.structure)
"Return `structure` field."
structure(l::L) where {L <: AbstractLabel} = has_structure(l) ? l.structure : nothing

has_graphics(l::L) where {L <: AbstractLabel} =
    hasproperty(l, :graphics) && !isnothing(l.graphics)
graphics(l::L) where {L <: AbstractLabel} =
    has_graphics(l) ? l.graphics : nothing

has_tools(l::L) where {L <: AbstractLabel} = has_tools(l.com)#! && !isempty(tools(l))
#    hasproperty(l, :tools) && !isnothing(l.tools)
tools(l::L) where {L <: AbstractLabel} = tools(l.com)

has_labels(l::L) where {L <: AbstractLabel} = has_labels(l.com)#! && !isempty(labels(l))
#    hasproperty(l, :labels) && !isnothing(l.labels)
labels(l::L) where {L <: AbstractLabel} = labels(l.com)

has_label(l::L, tagvalue::Symbol)  where {L <: AbstractLabel}= if has_labels(l)
    has_label(labels(l), tagvalue)
else
    false
end

"""
$(TYPEDEF)
Label that may be displayed.
It differs from an Attribute Label by possibly having a [`Graphics`](@ref) field.
"""
abstract type Annotation <: AbstractLabel end

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Wrap a `PnmlDict` that may be the root of an XML-tree.

Used for labels that do not have, or we choose not to use, a dedicated parse method.
Claimed labels will have a type defined to make use of the structure
defined by the pntd schema. See [`Name`](@ref), the only label defined in pnmlcore
and [`HLLabel`](@ref) for similat treatment of "unclaimed" high-level labels.
"""
@auto_hash_equals struct PnmlLabel <: Annotation
    tag::Symbol
    dict::PnmlDict
    xml::XMLNode
end

PnmlLabel(node::XMLNode; kw...) = PnmlLabel(unclaimed_label(node; kw...), node)
PnmlLabel(p::Pair{Symbol,PnmlDict}, node::XMLNode; kw...) =
        PnmlLabel(p.first, p.second, node; kw...)

tag(label::PnmlLabel) = label.tag
dict(label::PnmlLabel) = label.dict
xmlnode(label::PnmlLabel) = label.xml

function has_label(v::Vector{PnmlLabel}, tagvalue::Symbol)
    any(label->tag(label) === tagvalue, v)
end

function get_label(v::Vector{PnmlLabel}, tagvalue::Symbol)
    getfirst(l->tag(l) === tagvalue, v)
end

function get_labels(v::Vector{PnmlLabel}, tagvalue::Symbol)
    filter(l -> tag(l) === tagvalue, v)
end


"""
$(TYPEDEF)

Annotation label that uses <text> and <structure>.
"""
abstract type HLAnnotation <: AbstractLabel end



"""
$(TYPEDEF)
Objects of a Petri Net Graph are pages, arcs, nodes.
"""
abstract type PnmlObject end

"PnmlObjects are exected to have unique pnml ids."
pid(object::PnmlObject) = object.id

has_name(o::T) where {T <: PnmlObject} = o.name !== nothing
name(o::T) where {T <: PnmlObject} = has_name(o) ? o.name.text : ""

has_labels(o::T) where {T <: PnmlObject} = has_labels(o.com)
labels(o::T) where {T <: PnmlObject} = labels(o.com)

has_label(o::T, tagvalue::Symbol) where {T <: PnmlObject} =
    if has_labels(o)
        l = labels(o)
        l !== nothing ? has_label(l, tagvalue) : false
    else
        false
    end
get_label(o::T, tagvalue::Symbol) where {T <: PnmlObject} =
    if has_labels(o)
        l = labels(o)
        l !== nothing ? get_label(l, tagvalue) : nothing
    else
        nothing
    end

has_tools(o::T) where {T <: PnmlObject} = has_tools(o.com) && !isnothing(tools(o.com))
tools(o::T) where {T <: PnmlObject} = tools(o.com)
#TODO has_tool, get_tool

"""
$(TYPEDEF)
Petri Net Graph nodes are places, transitions.
"""
abstract type PnmlNode <: PnmlObject end

xmlnode(node::PnmlNode) = node.xml

"""
For common behavior shared by [`RefPlace`](@ref), [`RefTransition`](@ref).
"""
abstract type ReferenceNode <: PnmlNode end

refid(reference::ReferenceNode) = reference.ref

"""
$(TYPEDEF)

Tool specific objects can be attached to `PnmlObject`s and `AbstractLabel`s subtypes.
"""
abstract type AbstractPnmlTool end #TODO see ToolInfo

xmlnode(tool::AbstractPnmlTool) = tool.xml
