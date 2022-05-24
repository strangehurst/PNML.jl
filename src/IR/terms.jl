"""
Return default marking value based on `PNTD`. Has meaning of empty, as in `zero`.
"""
function default_term end
default_term(::PNTD) where {PNTD <: PnmlType} = zero(Integer) #!
default_term(::PNTD) where {PNTD <: AbstractContinuousCore} = zero(Float64) #!
default_term(::PNTD) where {PNTD <: AbstractHLCore} = Term() #!

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
