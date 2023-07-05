```@meta
CurrentModule = PNML
```

# Layers of Abstraction

!!! note "Graphics are elided from this discussion"

	Everywhere there are `ToolInfo`s in this discussion one may assume that there 
	is also an optional [`Graphics`](@ref) possible.
	
	While we parse such XML into "containers of strings" and [`Coordinate`](@ref)s. 
	No further use is implemented or planned. And no discussion of use is present.

The crude structure required by the pnmlcore schema:
PnmlModel
- Net
  * Pages
    - Places, Marking
    - Transitions, Condition
    - Arcs, Inscription
    - Toolinfos
    - Labels
    - Subpages
  * Name
  * Toolinfos
  * Labels

It is expected that conforming to pntd will be done at a higher level.

| Level      | Sorts              |   |
|------------|--------------------|---|
| Core       | Bool, Int          |   |
| PT         | Bool, Int          |   |
| Continuous | Bool, Float64      |   |
| Hybrid     | Bool, Int, Float64 |   |
| high-level | Bool, Int, Term    |   |
| Symmetric  | Bool, Int, Term    |   |
| PTHLPNG    | Bool, Int, Term    |   |

## Core Layer

What is permitted by the specification in a XML file will be a subset of the implementation.

Concepts from High-Level Petri Nets will be used in the Core layer. 

Sorts as defined in the specification are based on natural numbers and booleans.
High-level pntds use a`SortType` Term to define expressions as abstract syntax trees in XML.
Intermediate implementation of Terms uses [`AnyXmlNode`](@ref) to hold the AST as a tree of key, values where lhe leaf values are strings.

`sort_type(pntd)` returns the type to which a non-boolean term expression evaluates.
Is intended to be used by `Place`s whose markings are multisets of that sort.

| PNTD                  | Sort value        |   |
|-----------------------|-------------------|---|
| PnmlType              | Int               |   |
| AbstractContinuousNet | Float64           |   |
| AbstractHLCore        | eltype(DotSort()) |   |

Note that `eltype(DotSort())` should be `Int`.


Use Union{Bool, Int, Float64, Vector{AnyXmlNode}} as the set of types that a `Term`'s can contain.
Consider Bool, Int, Float64 as builtin-sorts, and Vector{AnyXmlNode} as "user defined" sorts.

```@setup types
using  PNML, InteractiveUtils, Markdown
list_type(f) = for pntd in values(PNML.PnmlTypeDefs.pnmltype_map)
    println(rpad(pntd, 15), " -> ", f(pntd))
end

```

```@example
using PNML # hide
PNML.PnmlTypeDefs.pnmltype_map
```
```@example types
list_type(PNML.pnmlnet_type)
```
```@example types
list_type(PNML.page_type)
```
```@example types
list_type(PNML.place_type)
```
```@example types
list_type(PNML.transition_type)
```
```@example types
list_type(PNML.arc_type)
```
```@example types
list_type(PNML.marking_type)
```
```@example types
list_type(PNML.condition_type)
```
```@example types
list_type(PNML.inscription_type)
```
```@example types
list_type(PNML.refplace_type)
```
```@example types
list_type(PNML.reftransition_type)
```

```@example types
list_type(PNML.sort_type)
```
```@example types
list_type(PNML.condition_value_type)
```
```@example types
list_type(PNML.inscription_value_type)
```
```@example types
list_type(PNML.marking_value_type)
```
```@example types
list_type(PNML.coordinate_value_type)
```
```@example types
list_type(PNML.term_value_type)
```
```@example types
list_type(PNML.rate_value_type)
```
	
