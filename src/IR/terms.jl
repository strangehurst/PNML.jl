"""
Return default marking value based on `PNTD`. Has meaning of empty, as in `zero`.

# Examples

```jldoctest; setup=:(using PNML; using PNML: default_term, default_one_term, default_zero_term, Term)
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
default_term(t::PNTD) where {PNTD <: AbstractHLCore} = default_one_term(t)
default_one_term(::PNTD)  where {PNTD <: AbstractHLCore} = Term(:empty, PnmlDict(:value => one(Integer)))
default_zero_term(::PNTD) where {PNTD <: AbstractHLCore} = Term(:empty, PnmlDict(:value => zero(Integer)))
#TODO Allow continuous-valued terms.

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Part of the many-sorted algebra attached to nodes on a Petri Net Graph.

 ast variants:
  - variable
  - operator
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
Evaluate a term by returning the ':value' in `dict`.
Assumes that `dict` is an `AbstractDictionary`.
"""
(t::Term)() = get(t.dict, :value, 1)
