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

typet = [
AbstractTrees.repr_tree(PNML.PnmlType)
AbstractTrees.repr_tree(PNML.PetriNet)
AbstractTrees.repr_tree(PNML.PnmlException)
AbstractTrees.repr_tree(PNML.PnmlObject)]
```

```@example type
foreach(typet) do t; println(t, "\n"); end # hide
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
