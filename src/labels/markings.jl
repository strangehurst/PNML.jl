# PNML (the ISO Specification) defines separate XML marking syntax variants for
# Place/Transition Nets (plain) and High-level (many-sorted).

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Number-valued label of [`Place`](@ref).
See [`PTNet`](@ref), [`ContinuousNet`](@ref), [`HLMarking`](@ref).

Is a functor that returns the `value`.
```
"""
struct Marking{T <: PnmlExpr} <: Annotation # TODO TermInterface
    #! hl adds text here
    term::T #! expression
    graphics::Maybe{Graphics} # PTNet uses TokenGraphics in tools rather than graphics.
    tools::Maybe{Vector{ToolInfo}}
end
# Allow any Number subtype, only a few concrete subtypes are expected.
Marking(m::Number) = Marking(NumberEx(m))
Marking(nx::NumberEx) = Marking(#=text is nothing,=# nx, nothing, nothing)

term(marking::Marking) = marking.term

# 1'value where value isa eltype(sortof(marking))
# because we assume a multiplicity of 1, and the sort is simple
#TODO add sort trait where simple means has concrete eltype
# Assume eltype(sortdefinition(marking)) == typeof(value(marking))

"""
$(TYPEDSIGNATURES)
Evaluate [`Marking`](@ref) instance by returning the evaluated TermInterface expression.

The `Marking` vs. `HLMarking` values differ by handling of token identity.
Place/Transition Nets (PNet, ContinuousNet) use collective token identity (map to ::Number).
High-level Nets (SymmetricNet, HLPNG) use individual token identity (colored petri nets).
TODO Cite John Baez for this distinction.

There is a multi-sorted algebra definition mechanism defined for HL Nets.
HLMarking values are a ground terms of this multi-sorted algebra.
There are abstract syntax trees defined by PNML.
We use TermInterface to implement/manipulate the terms.

Inscription and condition expressions may contain variables that map to a place's tokens.
HL Nets need to evaluate expressions as part of enabling and transition firing rules.
The result must be a ground term, and is used to update a marking.

For non-High,level nets, the inscrition TermInterface expression evaluates to a Number
and the condition is a boolean expression (default true).
"""
(mark::Marking)() = eval(toexpr(term(mark)::PnmlExpr, NamedTuple())) #~ same for HL #! Combine

# We give NHL (non-High-Level) nets a sort interface by mapping from type to sort.

basis(marking::Marking)   = sortref(marking)
sortref(marking::Marking) = basis(term(marking))::UserSort
sortof(marking::Marking)  = sortdefinition(namedsort(sortref(marking)))::NumberSort

# These are some <:Numbers that have sorts.
sortref(::Type{<:Int64})   = usersort(:integer)
sortref(::Type{<:Integer}) = usersort(:integer)
sortref(::Type{<:Float64}) = usersort(:real)
sortref(::Int64)   = usersort(:integer)
sortref(::Integer) = usersort(:integer)
sortref(::Float64) = usersort(:real)

sortof(::Type{<:Int64})   = sortdefinition(namedsort(:integer))::IntegerSort
sortof(::Type{<:Integer}) = sortdefinition(namedsort(:integer))::IntegerSort
sortof(::Type{<:Float64}) = sortdefinition(namedsort(:real))::RealSort
sortof(::Int64)   = sortdefinition(namedsort(:integer))::IntegerSort
sortof(::Integer) = sortdefinition(namedsort(:integer))::IntegerSort
sortof(::Float64) = sortdefinition(namedsort(:real))::RealSort

function Base.show(io::IO, ptm::Marking)
    print(io, indent(io), "Marking(")
    show(io, term(ptm))
    if has_graphics(ptm)
        print(io, ", ")
        show(io, graphics(ptm))
    end
    if has_tools(ptm)
        print(io, ", ")
        show(io, tools(ptm));
    end
    print(io, ")")
end

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Multiset of a sort labeling of a `Place` in a High-level Petri Net Graph.
See [`AbstractHLCore`](@ref), [`AbstractTerm`](@ref), [`Marking`](@ref).

Is a functor that returns the evaluated `value`.

> ... is a term with some multiset sort denoting a collection of tokens on the corresponding place, which defines its initial marking.
NB: The place's sorttype is not a multiset

> a ground term of the corresponding multiset sort. (does not contain variables)

> For every sort, the multiset sort over this basis sort is interpreted as
> the set of multisets over the type associated with the basis sort.

Multiset literals ... are defined using Add and NumberOf (multiset operators).

# Examples

```julia
; setup=:(using PNML; using PNML: HLMarking, NaturalSort, NumberConstant; PNML.fill_nonhl!(PNML.DECLDICT[]))
julia> m = HLMarking(PNML.pnmlmultiset(usersort(:integer), 1))
HLMarking(Bag(usersort(:integer), 1))

julia> m()
1
```
"""
mutable struct HLMarking{T<:PnmlExpr} <: HLAnnotation
    text::Maybe{String} # Supposed to be for human consumption.

    term::T # SymmetricNet restricts to Bag with basis sort matching place's sorttype.
    #~ NOTE #! Can HLPNG marking also be PnmlTuple, or other sort instance matching placetype?

    # The expression AST rooted at `term` in the XML stream.
    # Markings are ground terms, so no variables.
    # equal(sortof(basis(markterm)), sortof(placetype)) ||
    #     @error(string("HL marking sort mismatch,",
    #         "\n\t sortof(basis(markterm)) = ", sortof(basis(markterm)),
    #
    # Difference between Marking and HLMarking is the expression.
    # One is a number the other a term.

    #^ TermInterface, Metatheory rewrite rules used to set value of marking with a ground term.
    #^ Initial marking value set by evaluation of expression.
    #^ Firing rules update the marking value using rewrite rules.

    #! This is where the initial value expression is stored.
    #! The evaluated value is placed in the marking vector (as the initial value:).
    #! Firing rules use arc inscriptions to determine the new value for marking vector.

    # Terms are rewritten/optimized and hopefully compiled once.

    graphics::Maybe{Graphics}
    tools::Maybe{Vector{ToolInfo}}
end
HLMarking(t::PnmlExpr) = HLMarking(nothing, t)
HLMarking(s::Maybe{AbstractString}, t::PnmlExpr) = HLMarking(s, t, nothing, nothing)

"term(marking) -> PnmlExpr"
term(marking::HLMarking) = marking.term

"""
    (hlm::HLMarking)() -> PnmlMultieset
Evaluate a [`HLMarking`](@ref) term.
"""
(hlm::HLMarking)(varsub::NamedTuple=NamedTuple()) = begin
    #@show term(hlm) #toexpr(term(hlm)::PnmlExpr, varsub)
    #if toexpr(term(hlm)::PnmlExpr, varsub) isa Tuple
    #println("(hlm::HLMarking) stacktrace");  foreach(println, Base.StackTraces.stacktrace())
    #end
    eval(toexpr(term(hlm)::PnmlExpr, varsub)) # ground term = no variable substitutions.
end

basis(marking::HLMarking) = basis(term(marking))::UserSort
sortref(marking::HLMarking) = sortref(term(marking))::UserSort
sortof(marking::HLMarking) = sortdefinition(namedsort(sortref(marking)))::AbstractSort # value <: PnmlMultiset

function Base.show(io::IO, hlm::HLMarking)
    print(io, indent(io), "HLMarking(")
    show(io, text(hlm)); print(io, ", ")
    show(io, term(hlm)) # Term
    if has_graphics(hlm)
        print(io, ", ")
        show(io, graphics(hlm))
    end
    if has_tools(hlm)
        print(io, ", ")
        show(io, tools(hlm));
    end
    print(io, ")")
end

#--------------------------------------------------------------------------------------
marking_type(::Type{T}) where {T <: PnmlType} = Marking
marking_type(::Type{T}) where {T <: AbstractHLCore} = HLMarking

# From John Baez, et al _Categories of Nets_
# These are networks where the tokens have a collective identities.
marking_value_type(::Type{<:PnmlType}) =  Int #! NumberEx
marking_value_type(::Type{<:AbstractContinuousNet}) = Float64 #! NumberEx

# These are networks were the tokens have individual identities.
marking_value_type(::Type{<:AbstractHLCore}) = PnmlMultiset{<:Any, <:Any} #! PnmlExpr
#marking_value_type(::Type{<:PT_HLPNG}) # Restricted to: multiset of DotSort,

#--------------------------------------------------------------------------------------
# Basis sort can be, and are, restricted by/on PnmlType in the ISO standard.
# That is a statement about the XML file content. Allows a partial implementation that
# only supports the PTNet meta-model. SymmetricNet met-model, full fat HLPNG.
# The PnmlCoreNet, upon which PTNet, SymmetricNet, HLPNG, etc. are defined can be used
# to implement non-Petri net meta-models.
#
# PnmlCoreNet is a directed graph with extensible labels (and pages, tool specific).
#
# PNML.jl extensions: RealSort <: NumberSort

# PTNet and ContinuousNet:
#   NumberSort = IntegerSort, PositiveSort, NaturalSort, RealSort

# Symmetric Net:
#   BoolSort, FiniteIntRangeSort, FiniteEnumerationSort, CyclicEnumerationSort and DotSort

# High-Level Petri Net Graph adds:
#   IntegerSort, PositiveSort, NaturalSort
#   StringSort, ListSort
#
# Any number constant `value` can be represented by the operator/functor:
#    NumberConstant(::eltype(T), ::T) where {T<:NumberSort}, and NumberEx/TermInterface
#
# Implementation detail: the concrete NumberSort subtypes are Singleton types held in a field.
# NB: not all sort types are singletons, example FiniteEnumerationSort.

"""
$(TYPEDSIGNATURES)
Return default marking value based on `PnmlType`. Has meaning of empty, as in `zero`.
For high-level nets, the marking is an empty multiset whose basis matches `placetype`.
Others have a marking that is a `Number`.
"""
function default_marking(t::PnmlType)
    Marking(zero(marking_value_type(t))) #! Will not be a PnmlMultiset.
end
default_marking(::T) where {T<:AbstractHLCore} =
    error("No default_marking method for $T, did you mean default_hlmarking?")

function default_hlmarking(::T, placetype::SortType) where {T<:AbstractHLCore}
    el = def_sort_element(placetype)
    HLMarking(Bag(sortref(placetype), el, 0)) # empty multiset, el used for its type
end

# 2024-08-07 encountered the need to handle a <numberof> as an expression (NamedOpertor)
# Is a multiset operator. May hold variables in general.
# Markings restricted to ground terms without variables.
