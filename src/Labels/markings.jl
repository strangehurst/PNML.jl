"""
$(TYPEDEF)
$(TYPEDFIELDS)

Number-valued label of [`Place`](@ref).
See [`PTNet`](@ref), [`ContinuousNet`](@ref), [`HLMarking`](@ref).

Is a functor that returns the `value`.
```
"""
struct Marking{T <: PnmlExpr} <: Annotation
    #! HLMarking has text here #todo support for PTNet
    term::T #! expression
    graphics::Maybe{Graphics} # PTNet uses TokenGraphics in tools rather than graphics.
    tools::Maybe{Vector{ToolInfo}}
    declarationdicts::DeclDict
end

# Allow any Number subtype, only a few concrete subtypes are expected.
function Marking(m::Number, ddict::DeclDict)
    Marking(PNML.NumberEx(PNML.Labels._sortref(ddict, m)::SortRef, m), ddict)
end
Marking(nx::PNML.NumberEx, ddict::DeclDict) = Marking(nx, nothing, nothing, ddict)

decldict(marking::Marking) = marking.declarationdicts
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
(mark::Marking)() = eval(toexpr(term(mark)::PnmlExpr, NamedTuple(), decldict(mark))) #~ same for HL? #TODO! Combine

# We give NHL (non-High-Level) nets a sort interface by mapping from type to sort.
# These have basis == sortref.
basis(m::Marking)   = sortref(term(m))::SortRef
sortref(m::Marking) = _sortref(decldict(m), term(m))::SortRef
sortof(m::Marking)  = _sortof(decldict(m), term(m))::AbstractSort

# These are some <:Number that have sorts (usersort, namedsort duos).
_sortref(dd::DeclDict, ::Type{<:Int64})   = UserSortRef(:integer)
_sortref(dd::DeclDict, ::Type{<:Integer}) = UserSortRef(:integer)
_sortref(dd::DeclDict, ::Type{<:Float64}) = UserSortRef(:real)
_sortref(dd::DeclDict, ::Int64)   = UserSortRef(:integer)
_sortref(dd::DeclDict, ::Integer) = UserSortRef(:integer)
_sortref(dd::DeclDict, ::Float64) = UserSortRef(:real)

_sortref(dd::DeclDict, x::Any) = sortref(x)

_sortof(dd::DeclDict, ::Type{<:Int64})   = sortdefinition(namedsorts(dd)[:integer])::IntegerSort
_sortof(dd::DeclDict, ::Type{<:Integer}) = sortdefinition(namedsorts(dd)[:integer])::IntegerSort
_sortof(dd::DeclDict, ::Type{<:Float64}) = sortdefinition(namedsorts(dd)[:real])::RealSort
_sortof(dd::DeclDict, ::Int64)   = sortdefinition(namedsorts(dd)[:integer])::IntegerSort
_sortof(dd::DeclDict, ::Integer) = sortdefinition(namedsorts(dd)[:integer])::IntegerSort
_sortof(dd::DeclDict, ::Float64) = sortdefinition(namedsorts(dd)[:real])::RealSort
_sortof(dd::DeclDict, x::Any) = sortof(x)

function Base.show(io::IO, ptm::Marking)
    print(io, PNML.indent(io), "Marking(")
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

The term is a expression that will, when evaluated, have a `Sort`.
Implement the Sort interface.

# Examples

```julia
; setup=:(using PNML; using PNML: HLMarking, NaturalSort, ddict)
julia> m = HLMarking(PNML.pnmlmultiset(UserSortRef(:integer), 1; ddict))
HLMarking(Bag(UserSortRef(:integer), 1))

julia> m()
1
```
"""
struct HLMarking{T<:PnmlExpr} <: HLAnnotation
    text::Maybe{String} # Supposed to be for human consumption.

    term::T # SymmetricNet restricts to Bag with basis sort matching place's sorttype.
    #! This is where the initial value expression is stored.
    #! The evaluated value is placed in the marking vector (as the initial value:).
    #! Firing rules use arc inscriptions to determine the new value for marking vector.

    #~ NOTE #? Can HLPNG marking also be PnmlTuple, or other sort instance matching placetype?

    # The expression AST rooted at `term` wrapped in a `<structure>` in the XML stream.
    # Markings are ground terms, so no variables.

    # Difference between Marking and HLMarking is the expression.
    # One is a number the other a term.

    graphics::Maybe{Graphics}
    tools::Maybe{Vector{ToolInfo}}
    declarationdicts::DeclDict
end
#HLMarking(t::PnmlExpr, ddict) = HLMarking(nothing, t, ddict)
HLMarking(s::Maybe{AbstractString}, t::PnmlExpr, ddict) = HLMarking(s, t, nothing, nothing, ddict)

"term(marking) -> PnmlExpr"
term(marking::HLMarking) = marking.term

decldict(marking::HLMarking) = marking.declarationdicts

"""
    (hlm::HLMarking)() -> PnmlMultieset
Evaluate a [`HLMarking`](@ref) term. Is a ground term so no variables.
Used for initial marking value of a `Place` when creating the `initial_marking`.
"""
function (hlm::HLMarking)() #varsub::NamedTuple=NamedTuple())
    #@show term(hlm) #toexpr(term(hlm)::PnmlExpr, varsub, decldict(hlm))
    #if toexpr(term(hlm)::PnmlExpr, varsub, decldict(hlm)) isa Tuple
    #println("(hlm::HLMarking) stacktrace");  foreach(println, Base.StackTraces.stacktrace())
    #end
    eval(toexpr(term(hlm)::PnmlExpr, NamedTuple(), decldict(hlm))) # ground term = no variable substitutions.
end

# Sort interface
basis(marking::HLMarking) = basis(term(marking), decldict(marking))::SortRef
sortref(marking::HLMarking) = _sortref(decldict(marking), term(marking))::SortRef
sortof(m::HLMarking) = sortdefinition(namedsort(decldict(m), sortref(m)))::AbstractSort

function Base.show(io::IO, hlm::HLMarking)
    print(io, PNML.indent(io), "HLMarking(")
    show(io, text(hlm)); print(io, ", ")
    show(io, term(hlm))
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
PNML.marking_type(::Type{T}) where {T <: PnmlType} = Marking
PNML.marking_type(::Type{T}) where {T <: AbstractHLCore} = HLMarking

# From John Baez, et al _Categories of Nets_
# These are networks where the tokens have a collective identities.
PNML.value_type(::Type{Marking}, ::Type{<:PnmlType}) = eltype(NaturalSort) #::Int
PNML.value_type(::Type{Marking}, ::Type{<:AbstractContinuousNet}) = eltype(RealSort) #::Float64

# These are networks were the tokens have individual identities.
PNML.value_type(::Type{HLMarking}, ::Type{<:AbstractHLCore}) = PnmlMultiset{<:Any}
PNML.value_type(::Type{HLMarking}, ::Type{<:PT_HLPNG}) = PnmlMultiset{PNML.DotConstant}


#~ Note the close relation of marking value_type to inscription value_type.
#~ Inscription values are non-zero while marking values may be zdecldict(ero.

#--------------------------------------------------------------------------------------
# Basis sort can be, and are, restricted by/on PnmlType in the ISO 15909 standard.
# That is a statement about the XML file content. Allows a partial implementation that
# only supports the PTNet meta-model or SymmetricNet meta-model of Petri nets.
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
# Implementation detail: the concrete NumberSort subtypes are Singleton types held in a field.
# NB: not all sort types are singletons, example FiniteEnumerationSort.

"""
$(TYPEDSIGNATURES)
Return default marking value based on `PnmlType`. Has meaning of empty, as in `zero`.
For high-level nets, the marking is an empty multiset whose basis matches `placetype`.
Others have a marking that is a `Number`.
"""
function default(::Type{<:Marking}, t::PnmlType; ddict)
    Marking(zero(PNML.value_type(PNML.marking_type(t), t)), ddict) #! Will not be a PnmlMultiset.
end

default(::Type{<:Marking}, ::T; ddict) where {T <: AbstractHLCore} =
    error("No default_marking method for $T, did you mean default_hlmarking?")

function default(::Type{<:HLMarking}, ::AbstractHLCore, placetype::SortType; ddict)
    el = def_sort_element(placetype; ddict)
    HLMarking("default", PNML.Bag(sortref(placetype), el, 0), ddict) # empty multiset, el used for its type
end
