# Core types and methods are documented in interfaces.jl.

"""
Alias for Union{`T`, `Nothing`}.
"""
const Maybe{T} = Union{T, Nothing}

"""
Alias for Symbol that refers to something with an ID Symbol.
"""
const REFID = Symbol

#--------------------------------------------------------------------------------------
"""
$(TYPEDEF)

Objects of a Petri Net Graph are pages, arcs, nodes.
"""
abstract type AbstractPnmlObject end

"""
$(TYPEDEF)
Labels are attached to the Petri Net Graph objects. See [`AbstractPnmlObject`](@ref).
"""
abstract type AbstractLabel end

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

has_tools(o::AbstractPnmlObject) = hasproperty(o, :tools) && !isnothing(o.tools)
tools(o::AbstractPnmlObject)     = hasproperty(o, :tools) ? o.tools : nothing

has_graphics(o::AbstractPnmlObject) = hasproperty(o, :graphics) && !isnothing(o.graphics)
graphics(o::AbstractPnmlObject)     = o.graphics

# Jet once needed a hint about `o`.
function has_label(o::AbstractPnmlObject, tag::Union{Symbol, String, SubString{String}})
    (isnothing(o) && error("o is nothing")) ||
        (has_labels(o) && has_label(labels(o), tag))
end

function get_label(o::AbstractPnmlObject, tag::Union{Symbol, String, SubString{String}})
    (isnothing(o) && error("o is nothing")) ||
        (has_labels(o) && get_label(labels(o), tag))
end

"""
    labelof(x, sym::Symbol) -> Maybe{PnmlLabel}

`x` is anyting that supports has_label/get_label,
`tag` is the tag of the xml label element.
"""
function labelof(x, tag::Union{Symbol, String, SubString{String}})
    if has_labels(x)
        l = labels(x)
        return has_label(l, tag) ? @inbounds(get_label(l, tag))::PnmlLabel : nothing
    end
    return nothing
end

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

refid(r::ReferenceNode) = r.ref


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
See also [`Declaration`](@ref), [`Labels.SortType`](@ref), [`AbstractDeclaration`](@ref).

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
# - expression (PnmlExpr <: TermInterfce) that evaluates to an instance of output sort.
# - ordered sequence of zero or more input sorts #todo vector or tuple?
# - ordered sequence of zero or more subterms
# - one output sort
# and support methods to:
# - compare operator signatures for equality using sort eqality
# - output sort type to test against place sort type (and others)
#
# Note that a 0-ary operator is a constant.

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
condition_type(pntd::PnmlType)     = condition_type(typeof(pntd))
inscription_type(pntd::PnmlType)   = inscription_type(typeof(pntd))
coordinate_type(pntd::PnmlType)    = coordinate_type(typeof(pntd))

"""
    value_type(::Type{<AbstractLabel}, ::Type{<:PnmlType}) -> Type

Return the Type of a label's value.
"""
function value_type end
value_type(::Type{T}, pntd::PnmlType) where {T <: AbstractLabel}= value_type(T, typeof(pntd))

####################################################################
# """
#     SubstitutionDict = OrderderDict{REFID, Multiset}

# Variable ID used to access marking value. One for each variable of a transition.

# A higher level will produce candidate consistent substitution dictionaries,
# filtering them by one or more guards. `Condition` callable object guards are part of
# selecting enabled transition => subsitution dictionary firing pairs.
# The firing rule selects one of the firing pairs, using the substitution dictionary to
# construct postset marking updates.
# """
# const SubstitutionDict = OrderedDict{REFID, Multiset}
