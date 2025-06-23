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

Declarations ? declarationslabel holding sort, variable, operator

built-in sorts and operators (sorts have associated operators)
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
    prop_name === :text && return getfield(o, :text)::Union{Nothing,String,SubString{String}}
    prop_name === :graphics && return getfield(o, :graphics)::Maybe{Graphics}
    prop_name === :tools && return getfield(o, :tools)::Maybe{Vector{ToolInfo}}
    prop_name === :declarationdicts && return getfield(o, :declarationdicts)::Maybe{DeclDict}

    return getfield(o, prop_name)
end

# All Labels are expected to have a `text` field.
"Return `text` field. All labels are expected to have one that may be `nothing` or an empty string."
text(l::AbstractLabel) = (hasproperty(l, :text) && !isnothing(l.text)) ? l.text : ""
text(::Nothing) = ""

has_graphics(l::AbstractLabel) = hasproperty(l, :graphics) && !isnothing(l.graphics)
graphics(l::AbstractLabel) =  l.graphics

has_tools(l::AbstractLabel) = hasproperty(l, :tools) && !isnothing(l.tools)
tools(l::AbstractLabel) = l.tools

has_labels(l::AbstractLabel) = false # Labels DO NOT have sub-labels.

#--------------------------------------------

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
    tools::Maybe{Vector{ToolInfo}}
    declarationdicts::DeclDict
    #TODO validate in constructor: must have text or structure (depends on pntd?)
    #TODO make all labels have text &/or structure?
end

#------------------------------------------------------------------------------
# Pnml Label
#------------------------------------------------------------------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Wrap a PNML Label as parsed by `XMLDict`.
Use the XML tag as identifier.

Used for "unclaimed" labels that do not have, or we choose not to use,
a dedicated parse method. Claimed labels will have a type/parser defined to make use
of the structure defined by the pntd schema.

See also [`AnyElement`](@ref) which allows any well-formed XML,
while `PnmlLabel` is restricted to PNML Labels.
"""
@auto_hash_equals struct PnmlLabel <: Annotation
    # XMLDict uses symbols for attribute keys and string for elements/children keys.
    tag::Union{Symbol, String, SubString{String}}
    elements::Any # NB: PNML.XDVT is too complex
    declarationdicts::DeclDict
end

tag(label::PnmlLabel) = label.tag
elements(label::PnmlLabel) = label.elements

function Base.show(io::IO, labelvector::Vector{PnmlLabel})
    print(io, PNML.indent(io), "PnmlLabel[")
    io = PNML.inc_indent(io)
    for (i,label) in enumerate(labelvector)
        i > 1 && print(io, PNML.indent(io))
        print(io, "(",);
        show(io, tag(label)); print(io, ", "); dict_show(io, elements(label), 0);
        print(")")
        i < length(labelvector) && print(io, "\n")
    end
    print(io, "]")
end

function Base.show(io::IO, label::PnmlLabel)
    print(io, PNML.indent(io), "PnmlLabel(", tag(label), ", ", elements(label), ")")
end

#--------------------------------------
#TODO this is more general, make a utiity (and use somewhere else)?
"""
    hastag(x, tagvalue::Union{Symbol, String, SubString{String}}) -> Bool
Test anything with a `tag` accessor for equality with `tagvalue`.

Usage:
    `Iterators.filter(Fix2(hastag, :asymbol), iteratable)`
"""
hastag(l, tagvalue::Union{Symbol, String, SubString{String}}) = tag(l) == tagvalue

function labels(iteratable, tag::Union{Symbol, String, SubString{String}})
    isnothing(iteratable) && error("iteratable is nothing")
    Iterators.filter(Fix2(hastag, tag), iteratable)
end

"Return label matching `tagvalue`` or `nothing``."
function get_label(iteratable, tag::Union{Symbol, String, SubString{String}})
    first(labels(iteratable, tag))
end

"Return `true` if collection `iteratable` contains label with `tagvalue`."
function has_label(iteratable, tag::Union{Symbol, String, SubString{String}})
    !isempty(labels(iteratable, tag))
end
