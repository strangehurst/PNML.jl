function Base.getproperty(o::AbstractLabel, prop_name::Symbol)
    prop_name === :text && return getfield(o, :text)::Union{Nothing,String,SubString}
    #prop_name === :pntd && return getfield(o, :pntd)::PnmlType # Do labels have this?
    #prop_name === :xml  && return getfield(o, :xml)::XMLNode

    return getfield(o, prop_name)
end


"Return `true` if label has `text` field."
has_text(l::AbstractLabel) = hasproperty(l, :text) && !isnothing(l.text)

"Return `text` field."
text(l::AbstractLabel) = l.text

"Return `true` if label has a `structure` field."
has_structure(l::AbstractLabel) = hasproperty(l, :structure) && !isnothing(l.structure)

"Return `structure` field."
structure(l::AbstractLabel) = has_structure(l) ? l.structure : nothing

has_graphics(l::AbstractLabel) = !isnothing(l.graphics)
graphics(l::AbstractLabel) =  l.graphics

has_tools(l::AbstractLabel) = true
tools(l::AbstractLabel) = l.tools

has_labels(l::AbstractLabel) = false
labels(l::AbstractLabel) = error("$(typeof(l)) does not have labels attached")

# Labels include functors: markings, inscription, conditions #TODO test for Callable
_evaluate(x::AbstractLabel) = x()

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

"""
$(TYPEDEF)
$(TYPEDFIELDS)

High-level pnml labels are expected to have <text> and <structure> elements.
This concrete type is for "unclaimed" labels in a high-level petri net.

Some "claimed" `HLAnnotation` labels are [`Condition`](@ref),
[`Declaration`](@ref), [`HLMarking`](@ref), [`HLInscription`](@ref).
"""
struct HLLabel{PNTD} <: HLAnnotation
    text::Maybe{String}
    structure::Maybe{AnyElement}
    graphics::Maybe{Graphics}
    tools::Vector{ToolInfo}
    xml::XMLNode
    #TODO validate in constructor: must have text or structure (depends on pntd?)
    #TODO make all labels have text &/or structure?
end


#! TODO Add abstract options here.

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Pnml Label
#------------------------------------------------------------------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Used for "unclaimed" labels that do not have, or we choose not to use,
a dedicated parse method. Claimed labels will have a type/parser defined to make use
of the structure defined by the pntd schema.

Wrap a `AnyXmlNode[]` holding a pnml label. Use the XML tag as identifier.

See also [`AnyElement`](@ref). The difference is that `AnyElement` allows any well-formed XML,
while `PnmlLabel` is restricted to PNML Labels (with extensions in PNML.jl).
"""
@auto_hash_equals struct PnmlLabel <: Annotation
    tag::Symbol
    elements::Vector{AnyXmlNode} # This is a label made of the attributes and children of `tag``.
    xml::XMLNode
end

PnmlLabel(p::Pair{Symbol, Vector{AnyXmlNode}}, xml::XMLNode) = PnmlLabel(p.first, p.second, xml)

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
