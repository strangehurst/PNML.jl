
"""
$(TYPEDSIGNATURES)
Inscriptions, Markings, Conditions evaluate a value
that may be a scalar or a [`Term`](@ref) functor.

# Examples

```jldoctest; setup=(using PNML: _evaluate, Term)
julia> _evaluate(1)
1

julia> _evaluate(true)
true

julia> _evaluate(Term(:term, Dict(:value => 3))())
3
```
"""
function _evaluate end
_evaluate(x::Any) = x
_evaluate(x::T) where {T<:AbstractTerm} = x()
_evaluate(x::T) where {T<:AbstractSort} = x()
_evaluate(x::T) where {T<:AbstractLabel} = x()
