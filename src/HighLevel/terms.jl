"""
Return default empty [`Term`](@ref) of a High-Level Net based on `PNTD`.
Forwards to [`default_one_term`](@ref) meaning multiplicative identity or 1.
See [`default_zero_term`](@ref) for additive identity or 0.
Markings default to zero and inscriptions default to 1

# Examples

```jldoctest; setup=:(using PNML; using PNML: default_one_term, default_zero_term, Term)
julia> m = default_one_term(HLCoreNet())
Term(:one, 1)

julia> m()
1

julia> m = default_zero_term(HLCoreNet())
Term(:zero, 0)

julia> m()
0

```
"""
function default_term end
default_term(t::PnmlType) = default_one_term(t) #!relocate

#=
    Should be booleanconstant/numberconstant: one_term, zero_term, bool_term
=#

"""
$(TYPEDSIGNATURES)

One as integer, float, or empty term with a value of one.
"""
function default_one_term end
default_one_term() = default_one_term(PnmlCoreNet())
default_one_term(::PnmlType) = one(Int)# PTNet & PnmlCoreNet #!relocate
default_one_term(::AbstractContinuousNet) = one(Float64) #!relocate
default_one_term(::AbstractHLCore) = Term(:one, one(Int)) #! make Variable
default_one_term(x::Any) = throw(ArgumentError("expected a PnmlType, got: $(typeof(x))"))

term_value_type(::Type{<:PnmlType}) = Int
term_value_type(::Type{<:AbstractContinuousNet}) = Float64
term_value_type(::Type{<:AbstractHLCore}) = eltype(DotSort())

"""
$(TYPEDSIGNATURES)

Zero as integer, float, or empty term with a value of zero.
"""
function default_zero_term end
default_zero_term() = default_zero_term(PnmlCoreNet())
default_zero_term(::PnmlType) = zero(Int) #!relocate
default_zero_term(::AbstractContinuousNet) = zero(Float64) #!relocate
default_zero_term(::AbstractHLCore) = Term(:zero, zero(Int))
default_zero_term(x::Any) = throw(ArgumentError("expected a PnmlType, got: $(typeof(x))"))


"""
$(TYPEDSIGNATURES)

True as boolean or term with a value of `true`.
"""
function default_bool_term end
default_bool_term() = true
default_bool_term(::PnmlType) = true
default_bool_term(::AbstractHLCore) = Term(:bool, true)
default_bool_term(x::Any) = throw(ArgumentError("expected a PnmlType, got: $(typeof(x))"))

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Note that Term is an abstract element in the pnml specification with no XML tag.
Here we use it as a concrete wrapper around high-level many-sorted algebra terms
AND extend to also wrapping "single-sorted" values.

By adding `Bool`, `Int`, `Float64` it is possible for `PnmlCoreNet` and `ContinuousNet`
to use `Term`s, and for implenting `default_bool_term`, `default_one_term`, `default_zero_term`.

As part of the many-sorted algebra attached to nodes of a High-level Petri Net Graph,
Term`s are contained within the <structure> element of an annotation label,
See [`HLAnnotation`](@ref) concrete subtypes.

#TODO is it safe to assume that Bool, Int, Float64 are in the carrier set/basis set?

#! HL term is currently implemented as a wrapper of Vector{AnyXmlNode}. A tree of symbols with leafs that are strings.

# Functor

    (t::Term)([default_one_term(HLCoreNet())])

Term as functor requires a default value for missing values.

As a preliminary implementation evaluate a HL term by returning `:value` in `elements` or
evaluating `default_one_term(HLCoreNet())`.

See [`parse_marking_term`](@ref), [`parse_condition_term`](@ref),
[`parse_inscription_term`](@ref),  [`parse_type`](@ref), [`parse_sorttype_term`](@ref),
[`AnyElement`](@ref).

**Warning:** Much of the high-level is WORK-IN-PROGRES.
The type parameter is a sort. We enumerate some of the built-in sorts allowed.
Is expected that the term will evaluate to that type.
Is that called a 'ground term'? 'basis set'?
When the elements' value is a Vector{AnyXmlNode} external information is used to select the output type.
"""
struct Term{T <: Union{Bool, Int, Float64}} <: AbstractTerm
    tag::Symbol
    elements::Union{Bool, Int, Float64, Vector{AnyXmlNode}}
end

Term(s::Symbol, v::Union{Bool, Int, Float64}) = Term{typeof(v)}(s, v)
#Term(::Symbol, ::Vector{AnyXmlNode}}) requires knowing the sort type.

tag(t::Term)::Symbol = t.tag
elements(t::Term) = t.elements
output_sort(::Term{T})  where {T} = T
Base.eltype(t::Term) = typeof(elements(t))

(t::Term)(default = default_one_term(HLCoreNet())) = begin
    if eltype(t) <: Number
        return elements(t)
    else
        # Find any `:value` AnyXmlNode in elements. Really anything with a `value`.
        i = findfirst(x -> !isa(x, Number) && (tag(x) === :value), t.elements)
        if !isnothing(i)
            v = @inbounds value(t.elements[i])
            @assert typeof(v) isa eltype(t)
            return v
        else
            v = _evaluate(default)
            @assert typeof(v) isa eltype(t)
            return v
        end
    end
end
""
has_value(t::Term) = Iterators.any(x -> !isa(x, Number) && tag(x) === :value, t.elements)
