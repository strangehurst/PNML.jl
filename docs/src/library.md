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

```@eval
using AbstractTrees, PNML, InteractiveUtils, Markdown, GraphRecipes,Plots
AbstractTrees.children(x::Type) = subtypes(x)

Markdown.parse("""

	**TODO MAKE THIS PRETTY**

PNML type attribute string maps to:
	
	$(AbstractTrees.repr_tree(PNML.PnmlType))

Petri Nets:

	$(AbstractTrees.repr_tree(PNML.PetriNet))

This tree will be expanded.

Yeah, there is a primitive exception hierarchy:
	$(AbstractTrees.repr_tree(PNML.PnmlException))
""")
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
