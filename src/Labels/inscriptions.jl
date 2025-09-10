# """
# $(TYPEDEF)
# $(TYPEDFIELDS)

# Labels an Arc. See also [`Inscription`](@ref).
# ```
# """
# struct Inscription{T<:PnmlExpr} <: Annotation
#     term::T #! expression
#     graphics::Maybe{Graphics}
#     toolspecinfos::Maybe{Vector{ToolInfo}}
#     declarationdicts::DeclDict
# end

# Inscription(ex::PNML.NumberEx, ddict) = Inscription(ex, nothing, nothing, ddict)

# decldict(inscription::Inscription) = inscription.declarationdicts
# term(i::Inscription) = i.term
# sortref(i::Inscription) = _sortref(decldict(i), term(i))::SortRef
# sortof(i::Inscription) = sortdefinition(namedsort(decldict(i), sortref(i)))::NumberSort

# function (i::Inscription)(varsub::NamedTuple)
#     eval(toexpr(term(i), varsub, decldict(i)))::Number
# end

# variables(::Inscription) = () # There are no Variables in non-high-level nets.

# function Base.show(io::IO, inscription::Inscription)
#     print(io, "Inscription(")
#     show(io, term(inscription))
#     if has_graphics(inscription)
#         print(io, ", ")
#         show(io, graphics(inscription))
#     end
#     if has_tools(inscription)
#         print(io, ", ")
#         show(io, toolinfos(inscription))
#     end
#     print(io, ")")
# end

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Labels an Arc with a expression term .

`Inscription(t::PnmlExpr)()` is a functor evaluating the expression and
returns a value of the `eltype` of sort of inscription.
"""
struct Inscription{T <: PnmlExpr, N} <: HLAnnotation
    text::Maybe{String}
    term::T # expression whose output sort is the same as adjacent place's sorttype.
    graphics::Maybe{Graphics}
    toolspecinfos::Maybe{Vector{ToolInfo}}
    vars::NTuple{N,REFID} # default N is zero
    declarationdicts::DeclDict
end

decldict(i::Inscription) = i.declarationdicts
term(i::Inscription) = i.term
sortref(i::Inscription) = _sortref(decldict(i), term(i))::SortRef
sortof(i::Inscription) = sortdefinition(namedsort(decldict(i), sortref(i)))::PnmlMultiset #TODO other sorts

function (inscription::Inscription)(varsub::NamedTuple)
    eval(toexpr(term(inscription), varsub, decldict(inscription)))
end

variables(inscription::Inscription) = inscription.vars

function Base.show(io::IO, inscription::Inscription)
    print(io, "Inscription(")
    show(io, text(inscription)); print(io, ", "),
    show(io, term(inscription))
    if has_graphics(inscription)
        print(io, ", ")
        show(io, graphics(inscription))
    end
    if has_tools(inscription)
        print(io, ", ")
        show(io, toolinfos(inscription));
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
PNML.inscription_type(::Type{T}) where {T<:AbstractHLCore} = Inscription{<:PnmlExpr}

#!============================================================================
#! inscription value_type must match adjacent place marking value_type
#! with inscription being PositiveSort and marking being NaturalSort.
#!============================================================================

PNML.value_type(::Type{Inscription}, ::Type{<:PnmlType})              = eltype(PositiveSort) #::Int
PNML.value_type(::Type{Inscription}, ::Type{<:AbstractContinuousNet}) = eltype(RealSort) #::Float64
PNML.value_type(::Type{Inscription}, ::Type{<:AbstractHLCore}) = PnmlMultiset{<:Any}
PNML.value_type(::Type{Inscription}, ::Type{<:PT_HLPNG}) = PnmlMultiset{PNML.DotConstant}

function default(::Type{<:Inscription}, pntd::PnmlType, placetype::SortType; ddict::DeclDict)
    Inscription(nothing, PNML.NumberEx(UserSortRef(:natural), one(Int)), nothing, nothing, (), ddict)
end
function default(::Type{<:Inscription}, pntd::AbstractContinuousNet, placetype::SortType; ddict::DeclDict)
    Inscription(nothing, PNML.NumberEx(UserSortRef(:real), one(Float64)), nothing, nothing, (), ddict)
end
function default(::Type{<:Inscription}, ::AbstractHLCore, placetype::SortType; ddict)
    basis = sortref(placetype)::SortRef
    el = def_sort_element(placetype; ddict)
    Inscription(nothing, PNML.Bag(basis, el, 1), nothing, nothing, (), ddict) # non-empty singleton multiset.
end
