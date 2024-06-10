# Core types and methods are documented in interfaces.jl.

"""
Alias for Union{`T`, `Nothing`}.
"""
const Maybe{T} = Union{T, Nothing}

#--------------------------------------------------------------------------------------
"""
$(TYPEDEF)

Objects of a Petri Net Graph are pages, arcs, nodes.
"""
abstract type AbstractPnmlObject end
#! abstract type AbstractPnmlObject{PNTD<:PnmlType} end

# function Base.getproperty(o::AbstractPnmlObject, prop_name::Symbol)
#     prop_name === :id   && return getfield(o, :id)::Symbol
#     prop_name === :pntd && return getfield(o, :pntd)::PnmlType #! abstract
#     prop_name === :namelabel && return getfield(o, :namelabel)::Maybe{Name}

#     return getfield(o, prop_name)
# end

pid(o::AbstractPnmlObject)        = o.id

#
# When a thing may be nothing, any collection is expected to be non-empty.
# Strings may be empty. Don't blame us when someone else objects.
#
has_name(o::AbstractPnmlObject)   = hasproperty(o, :namelabel) && !isnothing(getfield(o, :namelabel))
name(o::AbstractPnmlObject)       = has_name(o) ? text(o.namelabel) : ""
name(::Nothing) = ""

# labels and tools are vectors: isnothing vs isempty
has_labels(o::AbstractPnmlObject) = hasproperty(o, :labels) && !isnothing(o.labels)
labels(o::AbstractPnmlObject)     = o.labels

has_tools(o::AbstractPnmlObject) = hasproperty(o, :tools) && !isnothing(o.tools) #! && !isempty(getfield(o, :tools))
tools(o::AbstractPnmlObject)     = hasproperty(o, :tools) ? o.tools : nothing

has_graphics(o::AbstractPnmlObject) = hasproperty(o, :graphics) && !isnothing(o.graphics)
graphics(o::AbstractPnmlObject)     = o.graphics

has_label(o::AbstractPnmlObject, tagvalue::Symbol) = has_labels(o) && has_label(labels(o), tagvalue)
get_label(o::AbstractPnmlObject, tagvalue::Symbol) = has_labels(o) && get_label(labels(o), tagvalue)


#--------------------------------------------
"""
$(TYPEDEF)
Petri Net Graph nodes are [`Place`](@ref), [`Transition`](@ref).
They are the source or target of an [`Arc`](@ref)
"""
abstract type AbstractPnmlNode{PNTD} <: AbstractPnmlObject end

"""
$(TYPEDEF)
For common behavior shared by [`RefPlace`](@ref), [`RefTransition`](@ref)
used to connect [`Page`](@ref) together.
"""
abstract type ReferenceNode <: AbstractPnmlObject end

function Base.getproperty(rn::ReferenceNode, name::Symbol)
    name === :ref && return getfield(rn, :ref)::Symbol
    return getfield(rn, name)
end

"Return the `id` of the referenced node."
refid(r::ReferenceNode) = r.ref

#------------------------------------------------------------------------------
# Abstract Label
#------------------------------------------------------------------------------
"""
$(TYPEDEF)
Labels are attached to the Petri Net Graph objects. See [`AbstractPnmlObject`](@ref).
"""
abstract type AbstractLabel end

#--------------------------------------------
"""
$(TYPEDEF)
Tool specific objects can be attached to
[`AbstractPnmlObject`](@ref)s and [`AbstractLabel`](@ref)s subtypes.
"""
abstract type AbstractPnmlTool end #TODO see ToolInfo

"Dictionary filled by `XMLDict`"
const DictType = LittleDict{Union{Symbol,String}, Any}

const XDVT2 = Union{DictType,  String,  SubString{String}}

"XMLDict values type. Maybe too large for union-splitting."
const XDVT = Union{XDVT2, Vector{XDVT2}}

tag(d::DictType)   = first(keys(d)) # Expect only one key here, String or Symbol
value(d::DictType) = d[tag(d)]
value(s::Union{String, SubString{String}}) = s

function Base.show(io::IO, m::MIME"text/plain", d::DictType)
    show(io, d)
end
function Base.show(io::IO, d::DictType)
    dict_show(IOContext(io, :typeinfo => DictType), d)
end

#--------------------------------------------
# Terms & Sorts
#--------------------------------------------
"""
$(TYPEDEF)
Terms are part of the multi-sorted algebra that is part of a High-Level Petri Net.

An abstract type in the pnml XML specification, concrete `Term`s are variables and operators
found within the <structure> element of a label.

Notably, a `Term` is not a PnmlLabel (or a PNML Label).

# References
See also [`Declaration`](@ref), [`SortType`](@ref), [`AbstractDeclaration`](@ref).

[Term_(logic)](https://en.wikipedia.org/wiki/Term_(logic)):
> A first-order term is recursively constructed from constant symbols, variables and function symbols.

> Besides in logic, terms play important roles in universal algebra, and rewriting systems.

> more convenient to think of a term as a tree.

> A term that doesn't contain any variables is called a ground term

> When the domain of discourse contains elements of basically different kinds,
> it is useful to split the set of all terms accordingly.
> To this end, a sort (sometimes also called type) is assigned to each variable and each constant symbol,
> and a declaration...of domain sorts and range sort to each function symbol....

[Type_theory](https://en.wikipedia.org/wiki/Type_theory)
> term in logic is recursively defined as a constant symbol, variable, or a function application, where a term is applied to another term

> if t is a term of type σ → τ, and s is a term of type σ, then the application of t to s, often written (t s), has type τ.

[Lambda terms](https://en.wikipedia.org/wiki/Lambda_calculus#Lambda_terms):
> The term redex, short for reducible expression, refers to subterms that can be reduced by one of the reduction rules.

See [Metatheory](https://github.com/JuliaSymbolics/Metatheory.jl)
and [SymbolicUtils](https://github.com/JuliaSymbolics/SymbolicUtils.jl)

"""
abstract type AbstractTerm end

"""
$(TYPEDEF)
Variables are part of the high-level pnml many-sorted algebra.
"""
abstract type AbstractVariable <: AbstractTerm end

"""
$(TYPEDEF)
Operators are part of the high-level pnml many-sorted algebra.

> ...can be a built-in constant or a built-in operator, a multiset operator which among others
> can construct a multiset from an enumeration of its elements, or a tuple operator.
> Each operator has a sequence of sorts as its input sorts, and exactly one output sort,
> which defines its signature.

See [`NamedOperator`](@ref) and [`ArbitraryOperator`](@ref).
"""
abstract type AbstractOperator <: AbstractTerm end

# Expect each operator instance to have fields:
# - definition of expression (PNML Term) that evaluates to an instance of an output sort.
# - ordered sequence of zero or more input sorts #todo vector or tuple?
# - one output sort
# and support methods to:
# - compare operator signatures for equality using sort eqality
# - output sort type to test against place sort type (and others)
#
# Note that a zero input operator is a constant.



"""
$(TYPEDEF)
Part of the high-level pnml many-sorted algebra. See  [`SortType`](@ref).

NamedSort is an AbstractTerm that declares a definition using an AbstractSort.
The pnml specification sometimes uses overlapping language.

From the 'primer': built-in sorts of Symmetric Nets are the following:
booleans, integerrange, finite enumerations, cyclic enumerations, permutations and dots.
And partitions.

The `eltype` is expected to be a concrete subtype of `Number` such as `Int`, `Bool` or `Float64`.

# Extras

Notes:
- `NamedSort` is a [`SortDeclaration`](@ref). [`HLPNG`](@ref) adds [`ArbitrarySort`](@ref).
- `UserSort` holds the id symbol of a `NamedSort`.
- Here 'type' means a 'term' from the many-sorted algebra.
- We use sorts even for non-high-level nets.
- Expect `eltype(::AbstractSort)` to return a concrete subtype of `Number`.
"""
abstract type AbstractSort end

#--------------------------------------------
# Any Element
#--------------------------------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Hold well-formed XML. See also [`ToolInfo`](@ref) and [`PnmlLabel`](@ref).

Creates a tree whose nodes are `Union{DictType, String, SubString{String}}`.
#TODO when can there be leaf nodes of String, Substring{String?}
See [`DictType`](@ref).
"""
@auto_hash_equals struct AnyElement
    tag::Symbol # XML tag
    elements::XDVT
end
AnyElement(s::AbstractString, elems) = AnyElement(Symbol(s), elems)

tag(a::AnyElement) = a.tag
elements(a::AnyElement) = a.elements # label elements

function Base.show(io::IO, label::AnyElement)
    print(io, "AnyElement(")
    show(io, tag(label)); print(io, ", ")
    dict_show(io, elements(label), 0)
    print(io, ")")
end

#--------------------------------------------
# Show Dict
#--------------------------------------------
"""
    dict_show(io::IO, x, 0())

Internal helper for things that contain `DictType`.
"""
function dict_show end

const increment=4
d_show(io::IO, x::Union{Vector,Tuple}, indent_by, before, after ) = begin
    print(io, before)
    for (i,e) in enumerate(x)
        dict_show(io, e, indent_by+increment) #
        i < length(x) && print(io, ",\n", indent(indent_by))
    end
    print(io, after)
end

dict_show(io::IO, d::DictType, indent_by::Int=0 ) = begin
    print(io, "(")
    #~    for (i,k) in enumerate(keys(d))
    for (i,k) in enumerate(pairs(d))
            print(io, "d[$(repr(k.first))] = ") #! Differs from `d_show` here.
        dict_show(io, #= And here. =# k.second, indent_by+increment) #!
        i < length(keys(d)) && print(io, ",\n", indent(indent_by))
    end
    print(io, ")")
end
#=
    Most things are symbol, DictType: AnyElement, PnmlLabel, Term, users of unparsed_tag.
    Note that Term also does Bool, Int, Float64, in addition to String.
    And that Term is (meant to be) Variable and Operator.

    This is the form of well-behaved XML: single rooted tree whose tag is the symbol.
    DictType is a collection of pairs: tag, value, where value may be a string/number or DictType.

    top-level tag symbol
    |   key is symbol or string
    |   |    value is dictionary, string, number
    |   |    |
    tag e1 = "string"!
        e2 = ee1 = tag2 x1 = vx1
                        x2 = vx2
                        x2 = vx2
                        x2 = vx2!
        e3 = 666!
        e4 = true!
        e5 = 3.14 #no ! here

    ! in newline
=#


dict_show(io::IO, v::Vector, indent_by::Int=0) = d_show(io, v, indent_by, '[', ']')
dict_show(io::IO, v::Tuple, indent_by::Int=0) =  d_show(io, v, indent_by, '(', ')')
dict_show(io::IO, s::SubString{String}, _::Int) = show(io, s)
dict_show(io::IO, s::AbstractString, _::Int) = show(io, s)
dict_show(io::IO, p::Pair, _::Int) = show(io, p)
dict_show(io::IO, p::Number, _::Int) = show(io, p)
dict_show(_::IO, x::Any, _::Int) = error("UNSUPPORTED dict_show(io, ::$(typeof(x)))")

#---------------------------------------------------------------------------
# Collect the Singleton to Type translations here.
# The part that needs to know Type details is defined elsewhere. :)
#---------------------------------------------------------------------------

pnmlnet_type(pntd::PnmlType)       = pnmlnet_type(typeof(pntd))
page_type(pntd::PnmlType)          = page_type(typeof(pntd))

place_type(pntd::PnmlType)         = place_type(typeof(pntd))
transition_type(pntd::PnmlType)    = transition_type(typeof(pntd))
arc_type(pntd::PnmlType)           = arc_type(typeof(pntd))
refplace_type(pntd::PnmlType)      = refplace_type(typeof(pntd))
reftransition_type(pntd::PnmlType) = reftransition_type(typeof(pntd))

marking_type(pntd::PnmlType)       = marking_type(typeof(pntd))
marking_value_type(pntd::PnmlType) = marking_value_type(typeof(pntd))

condition_type(pntd::PnmlType)       = condition_type(typeof(pntd))
condition_value_type(pntd::PnmlType) = condition_value_type(typeof(pntd))

inscription_type(pntd::PnmlType)       = inscription_type(typeof(pntd))
inscription_value_type(pntd::PnmlType) = inscription_value_type(typeof(pntd))

#! Term should be replaced by Variables and Operators. So not documented or tested.
term_value_type(pntd::PnmlType) = term_value_type(typeof(pntd))

coordinate_type(pntd::PnmlType)       = coordinate_type(typeof(pntd))
coordinate_value_type(pntd::PnmlType) = coordinate_value_type(typeof(pntd))

rate_value_type(pntd::PnmlType) = rate_value_type(typeof(pntd))
rate_value_type(::Type{<:PnmlType}) = Float64
