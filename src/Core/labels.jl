#=
A label may be associated with a node, an arc, or the net itself.

Things that are not labels (will be found as part of label's content) include Terms, Sorts.

Declarations are global labels of a High-level Petri Net attached to net or page and
used for defining variables, and user-defined sorts and operators.

Meta-models define the labels of the respective Petri net type (pntd).

Note: concepts of sorts, operators, declarations, and terms,
and how terms are constructed from variables and operators.
Implies this is 4 or 6 distinct things.

sort of a term is the sort of the variable or the output sort of the operator.

built-in sorts and operators
- Declarations
- Multisets
- Booleans
- Finite Enumerations, Cyclic Enumerations, and Finite Integer Ranges
- Partitions allow the definition of finite enumerations that are partitioned into sub-ranges
- Integer
- Strings
- Lists

user-defined variables are defined in a variable declaration

sort of Term is output sort of Operator or sort of Variable

operator can be: built-in constant, built-in operator, multiset operator, or tuple operator.

arbitrary sorts and operators
... introduce a new symbol without giving a definition
... used for constructing terms

Unparsed term ... text, which will not be parsed and interpreted by the tools

P/T Nets defined as restricted HLPNGs
- sorts Bool and Dot only.
- type of each place must refer to sort Dot
- no user declarations, nor variables, nor sorts, nor operators.
- transition conditions need to be the constant true, if this label is present.
- arc annotations and the initial markings are ground terms of the mulitset sort over Dot.

Symmetric Nets
- sort of a place must not be a multiset sort
-  for every sort, there is the operator all, which is a multiset that contains exactly one element of its basis sort

High-Level Petri Net Graphs extends Symmetric Nets
- declarations for sorts and functions
- additional built-in sorts for Integer, String, and List.

=#

function Base.getproperty(o::AbstractLabel, prop_name::Symbol)
    prop_name === :text && return getfield(o, :text)::Union{Nothing,String,SubString}
    #prop_name === :pntd && return getfield(o, :pntd)::PnmlType # Do labels have this?

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
end

PnmlLabel(p::Pair{Symbol, Vector{AnyXmlNode}}) = PnmlLabel(p.first, p.second)

tag(label::PnmlLabel) = label.tag
elements(label::PnmlLabel) = label.elements

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
