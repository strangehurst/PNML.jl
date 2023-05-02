"""
Return default empty [`Term`](@ref) of a High-Level Net based on `PNTD`.
Forwards to [`default_one_term`](@ref) meaning multiplicative identity or 1.
See [`default_zero_term`](@ref) for additive identity or 0.
Markings default to zero and inscriptions default to 1

# Examples

```jldoctest; setup=:(using PNML; using PNML: default_one_term, default_zero_term, Term)
julia> m = default_one_term(HLCoreNet())
Term(:empty, (value = 1,))

julia> m()
1

julia> m = default_zero_term(HLCoreNet())
Term(:empty, (value = 0,))

julia> m()
0

```
"""
function default_term end
default_term() = default_term(PnmlCoreNet()) #!relocate
default_term(t::PnmlType) = default_one_term(t) #!relocate

"""
$(TYPEDSIGNATURES)

One as integer, float, or empty term with a value of one.
"""
function default_one_term end
default_one_term() = default_one_term(PnmlCoreNet())
default_one_term(::PnmlType) = one(Int)# PTNet & PnmlCoreNet #!relocate
default_one_term(::AbstractContinuousNet) = one(Float64) #!relocate
default_one_term(::AbstractHLCore) = Term(:empty, (; :value => one(Int)))
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
default_zero_term(::AbstractHLCore) = Term(:empty, (; :value => zero(Int)))
default_zero_term(x::Any) = throw(ArgumentError("expected a PnmlType, got: $(typeof(x))"))

"""
Boolean termdefault_one_term(default_one_term(
"""
default_bool_term(::AbstractHLCore) = Term(:empty, (; :value => true))

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Part of the many-sorted algebra attached to nodes on a Petri Net Graph, `Term`s are
contained within the <structure> element of a `HLAnnotation`.

#! Note that Term is is an abstract element in the specification with no PNML tag.

Should conform to
the [`HLAnnotation`](@ref) interface. Namely <text>, <structure>, where <structure>
contains one element.  The element tag name is paired with its content:
a NamedTuple{Tag, Content} of children elements.

Note that 'structure' is not present in tag or tuple. This can be done for a `HLAnnotation`.
For more general well-formed-XML handling see [`AnyElement`](@ref).

 ast variants:
  - variable
  - operator

```jldoctest; setup=:(using PNML; using PNML: default_one_term, default_zero_term, Term)
julia> t = Term()
Term(:empty, ())

julia> t()
1
```
#! Term as functor requires a default value for missing values.
"""
struct Term <: AbstractTerm
    tag::Symbol
    elements::NamedTuple
    #TODO xml
end

Term() = Term(NamedTuple())
Term(tup::NamedTuple) = Term(:empty, tup)
Term(p::Pair{Symbol,<:NamedTuple}) = Term(p.first, p.second)
Term(p::Pair{Symbol,Vector{Pair{Symbol,Any}}}) = Term(p.first, namedtuple(p.second))

Base.convert(::Type{Maybe{Term}}, tup::NamedTuple)::Term = Term(tup)
Base.convert(::Type{Maybe{Term}}, v::Vector{Pair{Symbol,Any}})::Term = Term(namedtuple(v))

tag(t::Term)::Symbol = t.tag
elements(t::Term) = t.elements
#TODO xml(t::Term) = t.xml

"""
Evaluate a term by returning the ':value' in `elements` or a default value.

Default term value defaults to 1. Use the default argument to specify a default.

# Examples

```jldoctest; setup=:(using PNML; using PNML: default_term, default_one_term, default_zero_term, Term)
julia> t = Term()
Term(:empty, ())

julia> t()
1

julia> t(0)
0

julia> t(2.3)
2.3

```
"""
(t::Term)(default = default_one_term(HLCoreNet())) = begin
    value = if haskey(t.elements, :value)
        @inbounds t.elements[:value]
    else
        _evaluate(default)
    end
    return value
end
