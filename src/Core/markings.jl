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
struct Marking{N <: Number} <: Annotation
    value::N
    graphics::Maybe{Graphics} # PTNet uses TokenGraphics in tools rather than graphics.
    tools::Maybe{Vector{ToolInfo}}
    ids::Tuple
end
# Allow any Number subtype, only a few concrete subtypes are expected.
# Note that `ids` are used in the parsing but maybe not in docstrings.
Marking(value::Number; ids=(:nothing,)) = Marking(value, nothing, nothing; ids)
Marking(value::Number, graph, tool; ids) = Marking(value, graph, tool, ids)

# We give NHL (non-High-Level) nets a sort interface by mapping from type to sort.

# A marking is a multiset of elements of the sort.
# When the sort is dot, integer multiplicities are well understood & supported.

# In the NHL we want (require) that: #TODO

"""
    value(m::Marking) -> Number
"""
value(marking::Marking) = marking.value
# 1'value where value isa eltype(sortof(marking))
# because we assume a multiplicity of 1, and the sort is simple
#TODO add sort trait where simple means has concrete eltype
# Assume eltype(sortof(marking)) == typeof(value(marking))

basis(marking::Marking) = sortof(value(marking), decldict(netid(marking.ids)))
# For non-high-level the decldict will be populated (somehow, somewhere)
sortof(marking::Marking) = sortof(basis(marking)) # Mimic MultisetSort UserSort

sortof(i::Number, dd) = sortof(typeof(i), dd)
sortof(::Type{<:Integer}, dd) = has_usersort(dd, :integer) ? usersort(dd, :integer) : error("no usersort :integer")
sortof(::Type{<:Real}, dd)    = has_usersort(dd, :real)    ? usersort(dd, :real) : error("no usersort :real")

"Translate Number type to a tag symbol."
sorttag(i::Number) = sorttag(typeof(i))
sorttag(::Type{<:Integer}) = :integer
sorttag(::Type{<:Real})    = :real

"""
$(TYPEDSIGNATURES)
Evaluate [`Marking`](@ref) instance by returning its evaluated value.
"""
(mark::Marking)() = _evaluate(value(mark))

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
NB: the place's sorttype is not a multiset

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
struct HLMarking <: HLAnnotation
    text::Maybe{String} # Supposed to be for human consumption.
    term::AbstractTerm # of multiset sort whose basis sort is the same as place's sorttype
    graphics::Maybe{Graphics}
    tools::Maybe{Vector{ToolInfo}}
    ids::Tuple
    # TODO place reference or ids (where first is net and last is place)?
    # function HLMarking(str, t, graph, tool)
    #     sortof(t) isa MultisetSort
    #     #  PnmlMultiset
    #     HLMarking(str, t, graph, tool)
    # end
end
HLMarking(t::AbstractTerm; ids=(:nothing,)) = HLMarking(nothing, t; ids)
HLMarking(s::Maybe{AbstractString}, t::AbstractTerm; ids) = HLMarking(s, t, nothing, nothing, ids)
HLMarking(s::Maybe{AbstractString}, t::AbstractTerm, g, to; ids) = HLMarking(s, t, g, to, ids)

#HLMarking(t::AbstractTerm) = HLMarking(nothing, t)
#HLMarking(s::Maybe{AbstractString}, t::AbstractTerm) = HLMarking(s, t, nothing, nothing)

value(m::HLMarking) = m.term
basis(m::HLMarking) = basis(value(m))
sortof(m::HLMarking) = sortof(value(m)) #::MultisetSort #TODO sorts

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

"""
$(TYPEDSIGNATURES)
Evaluate a [`HLMarking`](@ref) instance by returning its term.
"""
(hlm::HLMarking)() = _evaluate(value(hlm))
#TODO convert to sort
#TODO query sort

marking_type(::Type{T}) where {T <: PnmlType} = Marking{marking_value_type(T)}
marking_type(::Type{T}) where {T<:AbstractHLCore} = HLMarking

# From John Baez, et al _Categories of Nets_
# These are networks where the tokens have a collective identities.
marking_value_type(::Type{<:PnmlType}) = Int
marking_value_type(::Type{<:AbstractContinuousNet}) = Float64

# These are networks were the tokens have individual identities.
marking_value_type(::Type{<:AbstractHLCore}) = PnmlMultiset
#marking_value_type(::Type{<:Symmetric}) # Restricted to: DotSort,

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
Return default marking value based on `PNTD`. Has meaning of empty, as in `zero`.
"""
function default_marking end
function default_marking(::T, placetype=nothing; ids::Tuple=()) where {T <: PnmlType}
    Marking(zero(marking_value_type(T)); ids)
end
function default_marking(pntd::AbstractHLCore; placetype::SortType, ids::Tuple)
    HLMarking(pnmlmultiset(default_zero_term(pntd, placetype), # empty multiset
                           sortof(default_zero_term(pntd)),
                           1); ids)
end

# At some point we will be feeding things to Metatheory/SymbolicsUtils,
# NumberConstant is a 0-ary functor
