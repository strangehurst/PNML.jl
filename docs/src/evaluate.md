## Evaluate possible functors

# Examples

```jldoctest; setup=(using PNML: _evaluate, Term, PnmlDict)
julia> _evaluate(1)
1

julia> _evaluate(true)
true

julia> _evaluate(nothing)


julia> _evaluate(Term(:term, PnmlDict(:value => 3))())
3
```
