# Library Reference
```@meta
CurrentModule = PNML
```

```@contents
Pages = ["library.md"]
Depth = 2
```

## Modules

Docstrings for modules. 

```@autodocs
Modules = [PNML]
Order = [:module]
```

## Types

Overview of some type hiearchies:

```@setup type
using AbstractTrees, PNML, InteractiveUtils, Markdown
#, GraphRecipes,Plots

AbstractTrees.children(x::Type) = subtypes(x)

typet = [
AbstractTrees.repr_tree(PNML.PnmlTypes.PnmlType)
AbstractTrees.repr_tree(PNML.PetriNet)
AbstractTrees.repr_tree(PNML.PnmlObject)
AbstractTrees.repr_tree(PNML.AbstractLabel)
AbstractTrees.repr_tree(PNML.AbstractPnmlTool)
AbstractTrees.repr_tree(PNML.PnmlException)
]
```
```@example type
foreach(typet) do t; println(t); end # hide
```

```@autodocs
Modules = [PNML]
Order = [:type]
```

## Constants

Docstrings for constants. This includes type  aliases.

```@autodocs
Modules = [PNML]
Order = [:constant]
```

## Functions

Docstrings for functions.

```@autodocs
Modules = [PNML]
Order = [:function]
```

## Macros

Docstrings for macros.

```@autodocs
Modules = [PNML]
Order = [:macro]
```
