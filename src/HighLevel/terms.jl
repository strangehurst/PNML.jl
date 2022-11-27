"""
Return default empty [`Term`](@ref) of a High-Level Net based on `PNTD`.
Forwards to [`default_one_term`](@ref) meaning multiplicative identity or 1.
See [`default_zero_term`](@ref) for additive identity or 0.
Markings default to zero and inscriptions default to 1

# Examples

```jldoctest; setup=:(using PNML; using PNML: default_one_term, default_zero_term, Term)
julia> m = default_one_term(HLCore())
Term(:empty, Dict(:value => 1))

julia> m()
1

julia> m = default_zero_term(HLCore())
Term(:empty, Dict(:value => 0))

julia> m()
0

```
"""
function default_term end
default_term(t::PnmlType) = default_one_term(t)

"""
$(TYPEDSIGNATURES)

One as integer, float, or empty term with a value of one.
"""
function default_one_term end
default_one_term(::PnmlType) = one(Int)# PTNet & PnmlCore
default_one_term(::AbstractContinuousNet) = one(Float64)
default_one_term(::AbstractHLCore) = Term(:empty, PnmlDict(:value => one(Int)))
default_one_term(x::Any) = error("argument must be subtype of PnmlType, got: $(typeof(x))")

"""
$(TYPEDSIGNATURES)

Zero as integer, float, or empty term with a value of zero.
"""
function default_zero_term end
default_zero_term(::PnmlType) = zero(Int)
default_zero_term(::AbstractContinuousNet) = zero(Float64)
default_zero_term(::AbstractHLCore) = Term(:empty, PnmlDict(:value => zero(Int)))
default_zero_term(x::Any) = error("argument must be subtype of PnmlType, got: $(typeof(x))")

#TODO Allow continuous-valued terms.

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Part of the many-sorted algebra attached to nodes on a Petri Net Graph.

 ast variants:
  - variable
  - operator

```jldoctest; setup=:(using PNML; using PNML: default_one_term, default_zero_term, Term)
julia> t = Term()
Term(:empty, Dict())

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

Term() = Term(:empty, PnmlDict())

Term(p::Pair{Symbol,PnmlDict}; kw...) = Term(p.first, p.second)

convert(::Type{Maybe{Term}}, pdict::PnmlDict) = Term(pdict)

tag(t::Term) = t.tag
dict(t::Term) = t.dict
#xml(t::Term) = t.xml

"""
Evaluate a term by returning the ':value' in `dict` or a default value.
Assumes that `dict` is an `AbstractDictionary`.
Default term value defaults to 1. Use the default argument to specify a default.

# Examples

```jldoctest; setup=:(using PNML; using PNML: default_term, default_one_term, default_zero_term, Term)
julia> t = Term()
Term(:empty, Dict())

julia> t()
1

julia> t(0)
0

julia> t(2.3)
2.3

```
"""
#(t::Term)() = t(default_one_term(HLCore())) #! HLCore restricts `Term` to AbstractHLCore subtypes
(t::AbstractTerm)(default=default_one_term(HLCore())) = _evaluate(get(t.dict, :value, default)) #
