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
end

Inscription(x::Number) = Inscription(sortref(x), x)
Inscription(s::UserSort, x::Number) = Inscription(NumberEx(s, x))
Inscription(ex::NumberEx) = Inscription(ex, nothing, nothing)

term(i::Inscription) = i.term # TODO when is the optimized away ()
(i::Inscription)(varsub::NamedTuple) = eval(toexpr(term(i), varsub))::Number

sortref(inscription::Inscription) = sortref(term(inscription))::UserSort
sortof(inscription::Inscription) = sortdefinition(namedsort(sortref(inscription)))::NumberSort

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

`HLInscription(t::PnmlExpr)()` is a functor evaluating the expression and a value of the `eltype` of sort of inscription.

# Examples
    ins() isa eltype(sortof(ins))

"""
struct HLInscription{T <: PnmlExpr, N} <: HLAnnotation
    text::Maybe{String}
    term::T # expression whose output sort is the same as adjacent place's sorttype.
    graphics::Maybe{Graphics}
    tools::Maybe{Vector{ToolInfo}}
    vars::NTuple{N,REFID}
end
HLInscription(t::PnmlExpr) = HLInscription(nothing, t)
HLInscription(s::Maybe{AbstractString}, t::PnmlExpr) = HLInscription(s, t, nothing, nothing, ())

(hlinscription::HLInscription)(varsub::NamedTuple) = eval(toexpr(term(hlinscription), varsub)) #TODO compile expression using varsub.

term(i::HLInscription) = i.term
sortref(hli::HLInscription) = sortref(term(hli))::UserSort
sortof(hli::HLInscription) = sortdefinition(namedsort(sortref(hli)))::PnmlMultiset #TODO other sorts

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

inscription_type(::Type{T}) where {T<:PnmlType}       = Inscription{<:PnmlExpr} #inscription_value_type(T)}
inscription_type(::Type{T}) where {T<:AbstractHLCore} = HLInscription{<:PnmlExpr} #inscription_value_type(T)}

inscription_value_type(::Type{<:PnmlType})              = eltype(PositiveSort)
inscription_value_type(::Type{<:AbstractContinuousNet}) = eltype(RealSort)
#
# PnmlMultiset{B,T} # basis
#~ basis B is a tupple holding REFID of a UserSort, used to index into other data structures.
#~ T is the Multiset type parameter,
inscription_value_type(::Type{<:AbstractHLCore}) = PnmlMultiset{<:Any, <:Any}

"""
$(TYPEDSIGNATURES)
Return default inscription value based on `PNTD`. Has meaning of unity, as in `one`.
"""
function default_inscription end
default_inscription(::T) where {T<:PnmlType}              = Inscription(one(Int))
default_inscription(::T) where {T<:AbstractContinuousNet} = Inscription(one(Float64))
default_inscription(::T) where {T<:AbstractHLCore} =
    error("no default_inscription method for $T, did you mean default_hlinscription")

"""
$(TYPEDSIGNATURES)

Return default `HLInscription` value based on `PNTD`.
Has meaning of unity, as in `one` of the adjacent place's sorttype.
#TODO Add element of sort selector
"""
function default_hlinscription(::T, placetype::SortType) where {T<:AbstractHLCore}
    basis = sortref(placetype)
    el = def_sort_element(placetype)
    HLInscription(Bag(basis, el, 1)) # non-empty singleton multiset.
end
