"""
$(TYPEDEF)
$(TYPEDFIELDS)

Number-valued label of [`Place`](@ref).

Is a functor that returns the `value`.
```
"""
struct Marking{T <: PnmlExpr} <: Annotation
    term::T #! expression
    text::Maybe{String} # Supposed to be for human consumption.
    graphics::Maybe{Graphics} # PTNet uses TokenGraphics in toolspecinfos rather than graphics.
    toolspecinfos::Maybe{Vector{ToolInfo}}
    declarationdicts::DeclDict
end

# Allow any Number subtype, only a few concrete subtypes are expected.
function Marking(m::Number, ddict::DeclDict)
    Marking(PNML.NumberEx(PNML.Labels._sortref(ddict, m)::AbstractSortRef, m), ddict)
end
Marking(nx::PNML.NumberEx, ddict::DeclDict) = Marking(nx, nothing, nothing, nothing, ddict)
Marking(t::PnmlExpr, s::Maybe{AbstractString}, ddict) = Marking(t, s, nothing, nothing, ddict)

decldict(marking::Marking) = marking.declarationdicts
term(marking::Marking) = marking.term

# 1'value where value isa eltype(sortof(marking))
# because we assume a multiplicity of 1, and the sort is simple
#TODO add sort trait where simple means has concrete eltype
# Assume eltype(sortdefinition(marking)) == typeof(value(marking))

# """
# $(TYPEDEF)
# $(TYPEDFIELDS)

# Multiset of a sort labeling of a `Place` in a High-level Petri Net Graph.
# See [`AbstractHLCore`](@ref), [`AbstractTerm`](@ref), [`Marking`](@ref).

# Is a functor that returns the evaluated `value`.

# > ... is a term with some multiset sort denoting a collection of tokens on the corresponding place, which defines its initial marking.
# NB: The place's sorttype is not a multiset

# > a ground term of the corresponding multiset sort. (does not contain variables)

# > For every sort, the multiset sort over this basis sort is interpreted as
# > the set of multisets over the type associated with the basis sort.

# Multiset literals ... are defined using Add and NumberOf (multiset operators).

# The term is a expression that will, when evaluated, have a `Sort`.
# Implement the Sort interface.

# # Examples

# ```julia
# ; setup=:(using PNML; using PNML: Marking, NaturalSort, ddict)
# julia> m = Marking(PNML.pnmlmultiset(NamedSortRef(:integer), 1; ddict))
# Marking(Bag(NamedSortRef(:integer), 1))

# julia> m()
# 1
# ```

# This is where the initial value EXPRESSION is stored.
# The evaluated value is placed in the marking vector (as the initial value:).
# Firing rules use arc inscriptions to determine the new value for marking vector.

# NOTE #? Can HLPNG marking also be PnmlTuple, or other sort instance matching placetype?

# Inscription and condition expressions may contain variables that map to a place's current marking.
# HL Nets need to evaluate expressions after variable substitution as part of enabling and transition firing rules.
# The result must be a ground term, and is used to update a marking vector.

# For non-High,level nets, the inscrition expression is a
# `NumberEx` (`<numberconstant> in HL-speak), default one`)
# and the condition is a boolean expression (default true).
# """
"""
$(TYPEDSIGNATURES)
Evaluate [`Marking`](@ref) instance by evaluating term expression.

Place/Transition Nets (PNet, ContinuousNet) use collective token identity (map to `Number`).
High-level Nets (SymmetricNet, HLPNG) use individual token identity (colored petri nets).

There is a multi-sorted algebra definition mechanism defined for HL Nets.
HL Net Marking values are a ground terms of this multi-sorted algebra.

These are used to give the initialize a marking vector that will then be updated by firing a transition.
"""
(mark::Marking)() = eval(toexpr(term(mark)::PnmlExpr, NamedTuple(), decldict(mark)))

basis(m::Marking)   = sortref(term(m))::AbstractSortRef
sortref(m::Marking) = _sortref(decldict(m), term(m))::AbstractSortRef
sortof(m::Marking)  = _sortof(decldict(m), term(m))::AbstractSort

function Base.show(io::IO, ptm::Marking)
    print(io, PNML.indent(io), "Marking(")
    show(io, term(ptm))
    if has_graphics(ptm)
        print(io, ", ")
        show(io, graphics(ptm))
    end
    if has_tools(ptm)
        print(io, ", ")
        show(io, toolinfos(ptm));
    end
    print(io, ")")
end


#--------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------

"""
    _sortref(dd::DeclDict, x) -> SortRef

When x isa Number, map to a NamedSortRef. Otherwise pass to sortref.
Note the `DeclDict` parameter is currently unused.
"""
function _sortref end

# These are some <:Number that have namedsorts.
_sortref(dd::DeclDict, ::Type{<:Int64})   = NamedSortRef(:integer)
_sortref(dd::DeclDict, ::Type{<:UInt64})  = NamedSortRef(:natural)
_sortref(dd::DeclDict, ::Type{<:Float64}) = NamedSortRef(:real)
_sortref(dd::DeclDict, ::Int64)   = NamedSortRef(:integer)
_sortref(dd::DeclDict, ::UInt64)  = NamedSortRef(:naturall)
_sortref(dd::DeclDict, ::Float64) = NamedSortRef(:real)

_sortref(dd::DeclDict, x::Any) = sortref(x)

#--------------------------------------------------------------------------------------
# These are networks where the tokens have a collective identities.
PNML.value_type(::Type{Marking}, ::PnmlType) = eltype(NaturalSort) #::Int
PNML.value_type(::Type{Marking}, ::AbstractContinuousNet) = eltype(RealSort) #::Float64

# These are networks were the tokens have individual identities.
function PNML.value_type(::Type{Marking}, pntd::AbstractHLCore)
    error("value_type(::Type{Marking}, $pntd) undefined.")
    # Base.show_backtrace(stdout, stacktrace())
    # PnmlMultiset{<:Any}
end

PNML.value_type(::Type{Marking}, ::PT_HLPNG) = PnmlMultiset{PNML.DotConstant}


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
function default(::Type{<:Marking}, pntd::PnmlType, placetype::SortType; ddict)
    D()&& @info "$pntd default Marking $placetype value_type = $(PNML.value_type(PNML.Marking, pntd)))"
    Marking(zero(PNML.value_type(PNML.Marking, pntd)), ddict) #! Will not be a PnmlMultiset.
end

function default(::Type{<:Marking}, pntd::AbstractHLCore, placetype::SortType; ddict)
    el = def_sort_element(placetype; ddict)
    D()&& @info "$pntd default Marking $placetype value_type = Bag($(sortref(placetype)), $el, 0))"
    Marking(PNML.Bag(sortref(placetype), el, 0), "default", ddict) # empty multiset, el used for its type
end
