"""
$(TYPEDEF)
$(TYPEDFIELDS)

Labels an Arc. See also [`HLInscription`](@ref).
```
"""
struct Inscription{T<:PnmlExpr} <: Annotation
    term::T #! expression
    graphics::Maybe{Graphics}
    tools::Maybe{Vector{ToolInfo}}
    declarationdicts::DeclDict
end

Inscription(ex::PNML.NumberEx, ddict) = Inscription(ex, nothing, nothing, ddict)

decldict(inscription::Inscription) = inscription.declarationdicts
term(i::Inscription) = i.term # TODO when is the optimized away ()
(i::Inscription)(varsub::NamedTuple) = eval(toexpr(term(i), varsub, decldict(i)))::Number

sortref(i::Inscription) = _sortref(decldict(i), term(i))::SortRef
sortof(i::Inscription) = sortdefinition(namedsort(decldict(i), sortref(i)))::NumberSort

# What variables are in the expression.
variables(::Inscription) = () # There are no Variables in non-high-level nets.

function Base.show(io::IO, inscription::Inscription)
    print(io, "Inscription(")
    show(io, term(inscription))
    if has_graphics(inscription)
        print(io, ", ")
        show(io, graphics(inscription))
    end
    if has_tools(inscription)
        print(io, ", ")
        show(io, tools(inscription))
    end
    print(io, ")")
end

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Labels an Arc with a term in a many-sorted algebra.
See also [`Inscription`](@ref) for non-high-level net inscriptions.

`HLInscription(t::PnmlExpr)()` is a functor evaluating the expression and
returns a value of the `eltype` of sort of inscription.

# Examples
    ins() isa eltype(sortof(ins))

"""
struct HLInscription{T <: PnmlExpr, N} <: HLAnnotation
    text::Maybe{String}
    term::T # expression whose output sort is the same as adjacent place's sorttype.
    graphics::Maybe{Graphics}
    tools::Maybe{Vector{ToolInfo}}
    vars::NTuple{N,REFID}
    declarationdicts::DeclDict
end

decldict(hli::HLInscription) = hli.declarationdicts

(hli::HLInscription)(varsub::NamedTuple) = eval(toexpr(term(hli), varsub, decldict(hli)))

term(hli::HLInscription) = hli.term
sortref(hli::HLInscription) = _sortref(decldict(hli), term(hli))::SortRef
sortof(hli::HLInscription) = sortdefinition(namedsort(decldict(hli), sortref(hli)))::PnmlMultiset #TODO other sorts

variables(i::HLInscription) = i.vars

function Base.show(io::IO, inscription::HLInscription)
    print(io, "HLInscription(")
    show(io, text(inscription)); print(io, ", "),
    show(io, term(inscription))
    if has_graphics(inscription)
        print(io, ", ")
        show(io, graphics(inscription))
    end
    if has_tools(inscription)
        print(io, ", ")
        show(io, tools(inscription));
    end
    print(io, ")")
end

# Non-high-level have a fixed, single value type for inscriptions, marks that is a Number.
# High-level use a multiset or bag over a basis or support set.
# Sometimes the basis is an infinite set. That is possible with HLPNG.
# Symmetric nets are restrictd to finite sets: enumerations, integer ranges.
# The desire to support marking & inscriptions that use Real value type introduces complications.
#
# Approaches
# - Only use Real for non-HL. The multiset implementation uses integer multiplicity.
#   Restrict the basis to ?
# - PnmlMultiset wraps a multiset and a sort. The sort and the contents of the multiset
#   must have the same type.
#
# The combination of basis and sortof is complicated.
# Terms sort and type are related. Type is very much a Julia mechanism. Like sort it is found
# in mathmatical texts that also use type.

# Julia Type is the "fixed" part.

PNML.inscription_type(::Type{T}) where {T<:PnmlType}       = Inscription{<:PnmlExpr}
PNML.inscription_type(::Type{T}) where {T<:AbstractHLCore} = HLInscription{<:PnmlExpr}

#!============================================================================
#! inscription value_type must match adjacent place marking value_type
#! with inscription being PositiveSort and marking being NaturalSort.
#!============================================================================

PNML.value_type(::Type{Inscription}, ::Type{<:PnmlType})              = eltype(PositiveSort) #::Int
PNML.value_type(::Type{Inscription}, ::Type{<:AbstractContinuousNet}) = eltype(RealSort) #::Float64
PNML.value_type(::Type{HLInscription}, ::Type{<:AbstractHLCore}) = PnmlMultiset{<:Any}
PNML.value_type(::Type{HLInscription}, ::Type{<:PT_HLPNG}) = PnmlMultiset{PNML.DotConstant}

function default(::Type{<:Inscription}, pntd::PnmlType; ddict::DeclDict)
    Inscription(PNML.NumberEx(UserSortRef(:natural), one(Int)), nothing, nothing, ddict)
end
function default(::Type{<:Inscription}, pntd::AbstractContinuousNet; ddict::DeclDict)
    Inscription(PNML.NumberEx(UserSortRef(:real), one(Float64)), nothing, nothing, ddict)
end
function default(::Type{<:Inscription}, pntd::AbstractHLCore; ddict::DeclDict)
    error("No default Inscription method for AbstractHLCore, did you mean HLInscription?")
end

function default(::Type{<:HLInscription}, ::AbstractHLCore, placetype::SortType; ddict)
    basis = sortref(placetype)::SortRef
    el = def_sort_element(placetype; ddict)
    HLInscription(nothing, PNML.Bag(basis, el, 1), nothing, nothing, (), ddict) # non-empty singleton multiset.
end
