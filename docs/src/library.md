# Library Reference

```@contents
Pages = ["library.md"]
Depth = 2
```

## Modules

```@autodocs
Modules = [PNML]
Order = [:module]
```

## Types


Overview of some type hiearchies
```@setup type
using AbstractTrees, PNML, InteractiveUtils, Markdown
#, GraphRecipes,Plots

AbstractTrees.children(x::Type) = subtypes(x)

pt=AbstractTrees.repr_tree(PNML.PnmlType)
pn=AbstractTrees.repr_tree(PNML.PetriNet)
pe=AbstractTrees.repr_tree(PNML.PnmlException)
```

```@example type
println(pt, "\n", pn, "\n", pe) # hide
```

```@autodocs
Modules = [PNML]
Order = [:type]
```

## Constants

```@autodocs
Modules = [PNML]
Order = [:constant]
```

## Functions

```@autodocs
Modules = [PNML]
Order = [:function]
```

## Macros

```@autodocs
Modules = [PNML]
Order = [:macro]
```
