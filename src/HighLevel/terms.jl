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
term_value_type(::Type{<:AbstractHLCore}) = Int

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

default_bool_term(::AbstractHLCore) = Term(:bool, true)

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Part of the many-sorted algebra attached to nodes on a Petri Net Graph, `Term`s are
contained within the <structure> element of a `HLAnnotation`.

#! Note that Term is is an abstract element in the specification with no PNML tag.

Should conform to the [`HLAnnotation`](@ref) interface. Namely <text>, <structure>,
where <structure> contains one element, a `Term`.  The `Term`s element tag name is
paired with its content: a NamedTuple{Tag, Content} of its children elements.

For more general well-formed-XML handling see [`AnyElement`](@ref).

 ast variants:
  - variable
  - operator

#! Term as functor requires a default value for missing values.
"""
struct Term <: AbstractTerm
    tag::Symbol #! Does this serve any function?
    elements::Union{Bool, Int, Float64, Vector{AnyXmlNode}}
end

#Term(tag::Symbol, x) = Term(tag, [x])
Term(ax::AnyXmlNode) = Term(:empty, [ax])
Term(p::Pair{Symbol,Vector{AnyXmlNode}}) = Term(p.first, p.second)

#Base.convert(::Type{Maybe{Term}}, tup::NamedTuple)::Term = Term(tup)

tag(t::Term)::Symbol = t.tag
elements(t::Term) = t.elements

"""
Evaluate a term by returning `:value` in `elements` or a default value.

Defaults to evauluating `default_one_term(HLCoreNet())`.
Use the `default` keyword argument to specify a different default.

The pnml specification treats 'Term' as an abstract UML2 type. We make it a concrete type.
See parse_sorttype_term, parse_type, parse_marking_term,
parse_condition_term, parse_inscription_term.

_Warning:_ Much of the high-level is WORK-IN-PROGRES. Term is implemented as a wrapper of
Vector{AnyXmlNode}. This is a tree of symbols with leafs that are strings.
"""
(t::Term)(default = default_one_term(HLCoreNet())) = begin
    if t.elements isa Number
        return t.elements
    else
        i = findfirst(x -> !isa(x, Number) && (tag(x) === :value), t.elements) # elements might be number
        if !isnothing(i)
            return @inbounds value(t.elements[i])
        else
            return _evaluate(default)
        end
    end
end

has_value(t::Term) = Iterators.any(x -> !isa(x, Number) && tag(x) === :value, t.elements)
