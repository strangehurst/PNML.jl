```@meta
CurrentModule = PNML
```

## Evaluate possible functors

Things that are functors:
  - Marking: return `Int`, `Float64`, or `Term`
  - Inscription: return `Int`, `Float64`, or `Term`
  - Condition: return `Bool`, or `Term`
  - Term: return a sort's value

```@setup methods
using AbstractTrees, PNML, InteractiveUtils, Markdown
```

[`_evaluate`](@ref)
```@example methods
methods(PNML._evaluate) # hide
```

# Examples

```jldoctest; setup=(using PNML: _evaluate, Term)
julia> _evaluate(1)
1

julia> _evaluate(true)
true
```
