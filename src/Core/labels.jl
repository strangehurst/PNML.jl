#------------------------------------------------------------------------------
# Abstract Label
#------------------------------------------------------------------------------
"""
$(TYPEDEF)
Labels are attached to the Petri Net Graph objects. See [`AbstractPnmlObject`](@ref).
"""
abstract type AbstractLabel end

function Base.getproperty(o::AbstractLabel, prop_name::Symbol)
    prop_name === :id   && return getfield(o, :id)::Symbol #! TODO do labels have ids?
    prop_name === :text && return getfield(o, :text)::Maybe{String} # AbstractString?
    prop_name === :com  && return getfield(o, :com)::ObjectCommon
    prop_name === :pntd && return getfield(o, :pntd)::PnmlType #! abstract, do labels have this? XXX
    prop_name === :xml  && return getfield(o, :xml)::XMLNode

    return getfield(o, prop_name)
end

xmlnode(::T) where {T<:AbstractLabel} = error("missing implementation of `xmlnode` for $T")

"Return `true` if label has `text` field."
has_text(l::AbstractLabel) = hasproperty(l, :text) && !isnothing(l.text)

"Return `text` field"
text(l::AbstractLabel) = l.text

"Return `true` if label has a `structure` field."
has_structure(l::AbstractLabel) = hasproperty(l, :structure) && !isnothing(l.structure)

"Return `structure` field."
structure(l::AbstractLabel) = has_structure(l) ? l.structure : nothing

has_graphics(l::AbstractLabel) = has_graphics(l.com)
graphics(l::AbstractLabel) =  graphics(l.com)

has_tools(l::AbstractLabel) = has_tools(l.com)
tools(l::AbstractLabel) = tools(l.com)

has_labels(l::AbstractLabel) = has_labels(l.com)
labels(l::AbstractLabel) = labels(l.com)

has_label(l::AbstractLabel, tag::Symbol) = has_labels(l) ? has_label(labels(l), tag) : false

_evaluate(x::AbstractLabel) = x() # functor

#--------------------------------------------
"""
$(TYPEDEF)
Label that may be displayed.
Differs from an Attribute Label by possibly having a [`Graphics`](@ref) field.
"""

abstract type Annotation <: AbstractLabel end
"""
$(TYPEDEF)
Annotation label that uses <text> and <structure>.
"""
abstract type HLAnnotation <: AbstractLabel end

#TODO #! Add abstract options here.

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
"""
Node in a tree formed from XML. `tag`s are XML tags or attribute names.
Leaf `val` are strings.
NB: Assumes XML "content" nodes do not have child XML nodes.
"""
struct AnyXmlNode #! Needed by PnmlLabel, AnyElement
    tag::Symbol
    val::Union{Vector{AnyXmlNode}, String, SubString}
end

AnyXmlNode(x::Pair{Symbol, Vector{AnyXmlNode}}) = AnyXmlNode(x.first, x.second)

tag(axn::AnyXmlNode) = axn.tag
value(axn::AnyXmlNode) = axn.val


#------------------------------------------------------------------------------
# Pnml Label
#------------------------------------------------------------------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Wrap a `NamedTuple` holding as a pnml label. Use the XML tag as identifier.

Used for "unclaimed" labels that do not have, or we choose not to use,
a dedicated parse method. Claimed labels will have a type/parser defined to make use
of the structure defined by the pntd schema.

See also [`AnyElement`](@ref). The difference is that `AnyElement` allows any well-formed XML,
while `PnmlLabel` is restricted to PNML Labels (with extensions in PNML.jl).
"""
@auto_hash_equals struct PnmlLabel <: Annotation
    tag::Symbol
    elements::Vector{AnyXmlNode} # This is a label made of the attributes and children of `tag``.
    xml::XMLNode
end

PnmlLabel(p::Pair{Symbol, Vector{AnyXmlNode}}, xml::XMLNode) = PnmlLabel(p.first, p.second, xml)
#!PnmlLabel(p::Pair{Symbol, <:NamedTuple}, xml::XMLNode) = PnmlLabel(p.first, p.second, xml)

tag(label::PnmlLabel) = label.tag
elements(label::PnmlLabel) = label.elements
xmlnode(label::PnmlLabel) = label.xml

hastag(l, tagvalue) = tag(l) === tagvalue

function get_labels(v, tagvalue::Symbol)
    Iterators.filter(Fix2(hastag, tagvalue), v)
end

function get_label(v, tagvalue::Symbol)
    first(get_labels(v, tagvalue))
end

function has_label(v, tagvalue::Symbol)
    !isempty(get_labels(v, tagvalue))
end
