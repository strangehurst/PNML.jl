#------------------------------------------------------------------------------
# Abstract Label
#------------------------------------------------------------------------------
"""
$(TYPEDEF)
Labels are attached to the Petri Net Graph objects. See [`AbstractPnmlObject`](@ref).
"""
abstract type AbstractLabel end

function Base.getproperty(o::AbstractLabel, prop_name::Symbol)
    if prop_name === :id
        return getfield(o, :id)::Symbol
    elseif prop_name === :pntd
        return getfield(o, :pntd)::PnmlType #! abstract
    elseif prop_name === :xml
        return getfield(o, :xml)::XMLNode
    elseif prop_name === :com
        return getfield(o, :com)::ObjectCommon
    end
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

#------------------------------------------------------------------------------
# Pnml Label
#------------------------------------------------------------------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Wrap a `PnmlDict` for an `XMLNode` that is treated as a pnml label. Use the XML tag as identifier.

Used for "unclaimed" labels that do not have, or we choose not to use,
a dedicated parse method. Claimed labels will have a type/parser defined to make use
of the structure defined by the pntd schema.
"""
@auto_hash_equals struct PnmlLabel <: Annotation
    tag::Symbol
    dict::NamedTuple #! make into tuple
    xml::XMLNode
end

PnmlLabel(p::Pair{Symbol,Vector{Pair{Symbol,Any}}}, xml::XMLNode) = begin
    @show p.first typeof(p) typeof(p.second) typeof((; p.second...)) typeof(namedtuple(p.second))
    PnmlLabel(p.first, namedtuple(p.second), xml)
end
PnmlLabel(p::Pair{Symbol,<:NamedTuple}, node::XMLNode) = PnmlLabel(p.first, p.second, node)

tag(label::PnmlLabel) = label.tag
dict(label::PnmlLabel) = label.dict
xmlnode(label::PnmlLabel) = label.xml

function has_label(v::Vector{PnmlLabel}, tagvalue::Symbol)
    any(Fix2(hastag, tagvalue), v)
end

hastag(l, tagvalue) = tag(l) === tagvalue

function get_label(v::Vector{PnmlLabel}, tagvalue::Symbol)
    getfirst(Fix2(hastag, tagvalue), v)
end

function get_labels(v::Vector{PnmlLabel}, tagvalue::Symbol)
    filter(Fix2(hastag, tagvalue), v)
end
