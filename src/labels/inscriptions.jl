"""
$(TYPEDEF)
$(TYPEDFIELDS)

Labels an Arc. See also [`HLInscription`](@ref).

# Examples

```jldoctest; setup=:(using PNML: Inscription)
julia> i = Inscription(3)
Inscription(3)

julia> i()
3
```
"""
struct Inscription{T<:Number}  <: Annotation
    value::T #TODO make Inscription use TermInterface
    graphics::Maybe{Graphics}
    tools::Maybe{Vector{ToolInfo}}
end

Inscription(value::Number) = Inscription(value, nothing, nothing)

value(i::Inscription) = i.value #! returns <:Number
(inscription::Inscription)() = _evaluate(value(inscription)::Number) #! TODO term rewrite rule

sortref(inscription::Inscription) = sortref(value(inscription))::UserSort
sortof(inscription::Inscription) = sortdefinition(namedsort(sortref(inscription)))::NumberSort

function Base.show(io::IO, inscription::Inscription)
    print(io, "Inscription(")
    show(io, value(inscription))
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

`HLInscription(t::PnmlMultiset)()` is a functor returning a value of the `eltype` of sort of inscription.

# Examples
    ins() isa eltype(sortof(ins))

"""
struct HLInscription{T<:PnmlMultiset} <: HLAnnotation
    text::Maybe{String}
    term::T # Multiset whose basis sort is the same as adjacent place's sorttype.
    graphics::Maybe{Graphics}
    tools::Maybe{Vector{ToolInfo}}
end
#! XXX Make HLInscription use TermInterface
#! TODO CHANGE TO PnmlMultiset
# ```jldoctest; setup=:(using PNML; using PNML: HLInscription, NumberConstant, NaturalSort)
# julia> i2 = HLInscription(NumberConstant(3, NaturalSort()))
# HLInscription("", NumberConstant{Int64, NaturalSort}(3, NaturalSort()))

# julia> i2()
# 3

# julia> i3 = HLInscription("text", NumberConstant(1, NaturalSort()))
# HLInscription("text", NumberConstant{Int64, NaturalSort}(1, NaturalSort()))

# julia> i3()
# 1

# julia> i4 = HLInscription("text", NumberConstant(3, NaturalSort()))
# HLInscription("text", NumberConstant{Int64, NaturalSort}(3, NaturalSort()))

# julia> i4()
# 3
# ```
HLInscription(t::PnmlMultiset) = HLInscription(nothing, t)
HLInscription(s::Maybe{AbstractString}, t::PnmlMultiset) = HLInscription(s, t, nothing, nothing)

value(i::HLInscription) = i.term
sortref(hli::HLInscription) = sortref(value(hli))::UserSort
sortof(hli::HLInscription) = sortdefinition(namedsort(sortref(hli)))::PnmlMultiset

(hlinscription::HLInscription)() = _evaluate(value(hlinscription)::PnmlMultiset) #! TODO term rewrite rule

function Base.show(io::IO, inscription::HLInscription)
    print(io, "HLInscription(")
    show(io, text(inscription)); print(io, ", "),
    show(io, value(inscription))
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

inscription_type(::Type{T}) where {T<:PnmlType}       = Inscription{inscription_value_type(T)}
inscription_type(::Type{T}) where {T<:AbstractHLCore} = HLInscription{inscription_value_type(T)}

inscription_value_type(::Type{<:PnmlType})              = eltype(PositiveSort)
inscription_value_type(::Type{<:AbstractContinuousNet}) = eltype(RealSort)
#
#~ does this need to be a UnionAll
inscription_value_type(::Type{<:AbstractHLCore}) = PnmlMultiset{<:Any}

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
    el = def_sort_element(placetype)
    HLInscription(pnmlmultiset(sortref(placetype), el, 1)) # not empty multiset. singleton multiset
end
