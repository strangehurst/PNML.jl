# PNML (the ISO Specification) defines separate XML marking syntax variants for
# Place/Transition Nets (plain) and High-level (many-sorted).
# TODO Add variant for tuples? Enumerations? (-1, 0 , 1) et al. to avoid HL mechansim?
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Number-valued label of [`Place`](@ref).
See [`PTNet`](@ref), [`ContinuousNet`](@ref), [`HLMarking`](@ref).

Is a functor that returns the `value`.

# Examples

```jldoctest; setup=:(using PNML: Marking)
julia> m = Marking(1)
Marking(1)

julia> m()
1

julia> m = Marking(12.34)
Marking(12.34)

julia> m()
12.34
```
"""
struct Marking{N <: Number} <: Annotation # TODO TermInterface
    value::N
    graphics::Maybe{Graphics} # PTNet uses TokenGraphics in tools rather than graphics.
    tools::Maybe{Vector{ToolInfo}}
end
# Allow any Number subtype, only a few concrete subtypes are expected.
Marking(value::Number) = Marking(value, nothing, nothing)
Marking(value::Number, graph, tool) = Marking(value, graph, tool)

# We give NHL (non-High-Level) nets a sort interface by mapping from type to sort.

# A marking is a multiset of elements of the sort.
# When the sort is dot, integer multiplicities are well understood & supported.

# In the NHL we want (require) that: #TODO

"""
    value(m::Marking) -> Number
"""
value(marking::Marking) = marking.value::Number
# 1'value where value isa eltype(sortof(marking)) (<:Number)
# because we assume a multiplicity of 1, and the sort is simple
#TODO add sort trait where simple means has concrete eltype
# Assume eltype(sortof(marking)) == typeof(value(marking))

"""
$(TYPEDSIGNATURES)
Evaluate [`Marking`](@ref) instance by returning its value.

The `Marking` vs. `HLMarking` values differ by handling of token identity.
Place/Transition Nets (PNet, ContinuousNet) use collective token idenitiy (map to ::Number).
High-level Nets (SymmetricNet, HLPNG) use individual token identity (colored petri nets).
Cite John Baez for this distinction.

There is a multi-sorted algebra definition mechanism defined for HL Nets.
HLMarking values are a ground terms of this multi-sorted algebra.
There are abstract syntax trees defined by PNML.

HL Nets need to evaluate expressions as part of transition firing rules.
While being ground terms that contain no variables, HLMarking values are expressed
as ASTs. And thus need to be "evaluated".
"""
(mark::Marking)() = _evaluate(value(mark)) # Will be identity for ::Number #TODO rewite rule

# Non-high-level
basis(marking::Marking) = sortof(marking)
sortof(marking::Marking) = sortof(value(marking)) # Returns sort of a Number
# These are some <:Numbers that have sorts.
sortof(::Type{<:Int64})   = sortof(usersort(:integer))
sortof(::Type{<:Integer}) = sortof(usersort(:integer))
sortof(::Type{<:Float64}) = sortof(usersort(:real))
sortof(::Int64)   = sortof(usersort(:integer))
sortof(::Integer) = sortof(usersort(:integer))
sortof(::Float64) = sortof(usersort(:real))

"Translate Number type to a sort tag symbol."
sorttag(i::Number) = sorttag(typeof(i))
sorttag(::Type{<:Integer}) = :integer
sorttag(::Type{<:Float64}) = :real

function Base.show(io::IO, ptm::Marking)
    print(io, indent(io), "Marking(")
    show(io, value(ptm))
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

```jldoctest; setup=:(using PNML; using PNML: HLMarking, NaturalSort, NumberConstant)
julia> m = HLMarking("the text", NumberConstant(3, NaturalSort()))
HLMarking("the text", NumberConstant{Int64, NaturalSort}(3, NaturalSort()))

julia> m()
3
```
"""
struct HLMarking{T} <: HLAnnotation #! TODO TermInterface
    text::Maybe{String} # Supposed to be for human consumption.
    #! PnmlMultiset? multiset sort whose basis sort is the same as place's sorttype
    term::PnmlMultiset{T}  # With sort matching placesort.
    # PnmlMultiset is the result of evaluating the expression AST rooted at term.
    # Markings are ground terms, so no variables.

    graphics::Maybe{Graphics}
    tools::Maybe{Vector{ToolInfo}}
end
HLMarking(t::PnmlMultiset) = HLMarking(nothing, t)
HLMarking(s::Maybe{AbstractString}, t::PnmlMultiset) = HLMarking(s, t, nothing, nothing)
HLMarking(s::Maybe{AbstractString}, t::PnmlMultiset, g, to) = HLMarking(s, t, g, to)

value(marking::HLMarking) = marking.term
basis(marking::HLMarking) = basis(value(marking))
sortof(marking::HLMarking) = sortof(value(marking))

"""
$(TYPEDSIGNATURES)
Evaluate a [`HLMarking`](@ref) instance by returning its term.
"""
(hlm::HLMarking)() = _evaluate(value(hlm)) #! TODO rewrite rule

function Base.show(io::IO, hlm::HLMarking)
    print(io, indent(io), "HLMarking(")
    show(io, text(hlm)); print(io, ", ")
    show(io, value(hlm)) # Term
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

marking_type(::Type{T}) where {T <: PnmlType} = Marking{marking_value_type(T)}
marking_type(::Type{T}) where {T<:AbstractHLCore} = HLMarking

# From John Baez, et al _Categories of Nets_
# These are networks where the tokens have a collective identities.
marking_value_type(::Type{<:PnmlType}) = Int
marking_value_type(::Type{<:AbstractContinuousNet}) = Float64

# These are networks were the tokens have individual identities.
marking_value_type(::Type{<:AbstractHLCore}) = PnmlMultiset{<:Any}
#marking_value_type(::Type{<:PT_HLPNG}) # Restricted to: multiset of DotSort,

# basis sort can be, and are, restricted by/on PnmlType.
# Symmetric Nets:
#   BoolSort, FiniteIntRangeSort, FiniteEnumerationSort, CyclicEnumerationSort and DotSort
# High-Level Petri Net Graphs adds:
#   IntegerSort, PositiveSort, NaturalSort
#   StringSort, ListSort
#
# PNML.jl extensions: RealSort <: NumberSort
# Any number constant `value` can be represented by the operator/functor:
#    NumberConstant(::eltype(T), ::T) where {T<:NumberSort},
# Implementation detail: the concrete NumbeSort subtypes are Singleton types and that singleton is held in a field.
# NB: not all sort types are singletons, example FiniteEnumerationSort.

"""
$(TYPEDSIGNATURES)
Return default marking value based on `PnmlType`. Has meaning of empty, as in `zero`.
For high-level nets, the marking is an empty multiset whose basis matches `placetype`.
Others have a marking that is a `Number`.
"""
function default_marking end
function default_marking(::T) where {T<:PnmlType}
    Marking(zero(marking_value_type(T)))
end
default_marking(::T) where {T<:AbstractHLCore} =
    error("No default_marking method for $T, did you mean default_hlmarking?")

function default_hlmarking(::T, placetype::SortType) where {T<:AbstractHLCore}
    el = def_sort_element(placetype)
    HLMarking(pnmlmultiset(el, usersort(placetype), 0)) # empty, el used for its type
end

# At some point we will be feeding things to Metatheory/SymbolicsUtils,
# NumberConstant is a 0-ary functor
# (nc::NumberConstant{T})()

# 2024-08-07 encountered the need to handle a <numberof> as an expression (NamedOpertor)
# Is a multiset operator. May hold variables in general.
# Markings restricted to ground terms without variables.
