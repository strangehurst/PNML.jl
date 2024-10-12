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

"""
$(TYPEDEF)
Labels are attached to the Petri Net Graph objects. See [`AbstractPnmlObject`](@ref).
"""
abstract type AbstractLabel end

function Base.getproperty(o::AbstractLabel, prop_name::Symbol)
    prop_name === :text && return getfield(o, :text)::Union{Nothing,String,SubString{String}}
    #prop_name === :pntd && return getfield(o, :pntd)::PnmlType # Do labels have this?

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

has_labels(l::AbstractLabel) = false

# Some Labels are functors: marking, inscription, condition.
# Usually where it is possible to have a high-level term.
_evaluate(label::AbstractLabel) = begin println("_evaluate: AbstractLabel $(nameof(typeof(label)))"); label(); end
#error("_evaluate abstract label $(nameof(typeof(label)))")

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
struct HLLabel{PNTD} <: Annotation
    text::Maybe{String}
    structure::Maybe{AnyElement}
    graphics::Maybe{Graphics}
    tools::Maybe{Vector{ToolInfo}}
    #TODO validate in constructor: must have text or structure (depends on pntd?)
    #TODO make all labels have text &/or structure?
end

#------------------------------------------------------------------------------
# Pnml Label
#------------------------------------------------------------------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Wrap an `AbstractDict` holding a PNML Label as parsed by `XMLDict`. Use the XML tag as identifier.

Used for "unclaimed" labels that do not have, or we choose not to use,
a dedicated parse method. Claimed labels will have a type/parser defined to make use
of the structure defined by the pntd schema.

See also [`AnyElement`](@ref). The difference is that `AnyElement` allows any well-formed XML,
while `PnmlLabel` is restricted to PNML Labels (with extensions in PNML.jl).
"""
@auto_hash_equals struct PnmlLabel <: Annotation
    tag::Symbol
    elements::XDVT
end
PnmlLabel(s::AbstractString, elems) = PnmlLabel(Symbol(s), elems)

tag(label::PnmlLabel) = label.tag
elements(label::PnmlLabel) = label.elements

function Base.show(io::IO, labelvector::Vector{PnmlLabel})
    print(io, indent(io), "PnmlLabel[")
    io = inc_indent(io)
    for (i,label) in enumerate(labelvector)
        i > 1 && print(io, indent(io))
        print(io, "(",);
        show(io, tag(label)); print(io, ", "); dict_show(io, elements(label), 0);
        print(")")
        i < length(labelvector) && print(io, "\n")
    end
    print(io, "]")
end

function Base.show(io::IO, label::PnmlLabel)
    print(io, indent(io), "PnmlLabel(", tag(label), ", ", elements(label), ")")
end

#--------------------------------------
#TODO this is more general, make a utiity (and use somewhere else)?
"""
    hastag(x, tagvalue::Symbol) -> Function
Return method with one argument. Duck-typed to test anything with tag accessor.

# EXAMPLES
    Iterators.filter(Fix2(hastag, tagvalue), iteratable)
"""
hastag(l, tagvalue::Symbol) = tag(l) === tagvalue

"""
    get_labels(iteratable, s::Symbol) -> Iterator

Filter iteratable collection for elements having `s` as the `tag`.
"""
function get_labels(iteratable, tagvalue::Symbol)
    Iterators.filter(Fix2(hastag, tagvalue), iteratable)
end

"Return label matching `tagvalue`` or `nothing``."
function get_label(iteratable, tagvalue::Symbol)
    first(get_labels(iteratable, tagvalue))
end

"Return `true` if collection `v` contains label with `tagvalue`."
function has_label(iteratable, tagvalue::Symbol)
    @show typeof(iteratable)
    !isempty(get_labels(iteratable, tagvalue))
end

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Label of a <net> or <page> that holds zero or more declarations. The declarations are used
to define parts of the many-sorted algebra used by High-Level Petri Nets.

All the declarations in the <structure> are placed into a single per-net dictonary.
The text, graphics, and tools fields are expected to be nothing, but are present because,
being labels, it is allowed.
"""
@kwdef struct Declaration <: Annotation
    text::Maybe{String} = nothing
    ddict::DeclDict = DeclDict()
    graphics::Maybe{Graphics} = nothing
    tools::Maybe{Vector{ToolInfo}} = nothing
end

decldict(d::Declaration) = d.ddict
declarations(d::Declaration) = decldict(d)
Base.length(d::Declaration) = length(declarations(d))
Base.isempty(d::Declaration) = isempty(declarations(d))
