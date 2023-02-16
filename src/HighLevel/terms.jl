"""
Return default empty [`Term`](@ref) of a High-Level Net based on `PNTD`.
Forwards to [`default_one_term`](@ref) meaning multiplicative identity or 1.
See [`default_zero_term`](@ref) for additive identity or 0.
Markings default to zero and inscriptions default to 1

# Examples

```jldoctest; setup=:(using PNML; using PNML: default_one_term, default_zero_term, Term)
julia> m = default_one_term(HLCoreNet())
Term(:empty, IdDict{Symbol, Any}(:value => 1))

julia> PnmlDict
IdDict{Symbol, Any}

julia> m()
1

julia> m = default_zero_term(HLCoreNet())
Term(:empty, IdDict{Symbol, Any}(:value => 0))

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
default_one_term(::AbstractHLCore) = Term(:empty, PnmlDict(:value => one(Int)))
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
default_zero_term(::AbstractHLCore) = Term(:empty, PnmlDict(:value => zero(Int)))
default_zero_term(x::Any) = throw(ArgumentError("expected a PnmlType, got: $(typeof(x))"))

"""
Boolean termdefault_one_term(default_one_term(
"""
default_bool_term(::AbstractHLCore) = Term(:empty, PnmlDict(:value => true))

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Part of the many-sorted algebra attached to nodes on a Petri Net Graph.

 ast variants:
  - variable
  - operator

```jldoctest; setup=:(using PNML; using PNML: default_one_term, default_zero_term, Term)
julia> t = Term()
Term(:empty, IdDict{Symbol, Any}())

julia> t()
1
```
#! Term as functor requires a default value for missing values.
"""
struct Term{T<:AbstractDict}  <: AbstractTerm #TODO make mutable?
    tag::Symbol
    dict::T
  #TODO xml
end

Term() = Term(PnmlDict())
Term(d::PnmlDict) = Term(:empty, d)
Term(p::Pair{Symbol,PnmlDict}) = Term(p.first, p.second)

Base.convert(::Type{Maybe{Term}}, pdict::PnmlDict)::Term = Term(pdict)

tag(t::Term)::Symbol = t.tag
dict(t::Term) = t.dict
#TODO xml(t::Term) = t.xml

"""
Evaluate a term by returning the ':value' in `dict` or a default value.
Assumes that `dict` is an `AbstractDictionary`.
Default term value defaults to 1. Use the default argument to specify a default.

# Examples

```jldoctest; setup=:(using PNML; using PNML: default_term, default_one_term, default_zero_term, Term)
julia> t = Term()
Term(:empty, IdDict{Symbol, Any}())

julia> t()
1

julia> t(0)
0

julia> t(2.3)
2.3

```
"""
(t::Term)(default = default_one_term(HLCoreNet())) = begin
    value = if haskey(t.dict, :value)
        t.dict[:value]
    else
        _evaluate(default)
    end
    return value
end
condition_type(::Type{T}) where {T<:AbstractHLCore} = Condition{T, Term{PnmlDict}}
