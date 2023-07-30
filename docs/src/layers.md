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
    - Places, Marking, unclaimed labels  [SortType] [Capacity]
    - Transitions, Condition, unclaimed labels [rate]
    - Arcs, Inscription, unclaimed labels [ArcType]
    - Toolinfos [TokenGraphics]
    - Labels unclaimed, [Declaration]
    - Subpages
  * Name (everybody has name)
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

`default_sort_type(pntd)` returns the type to which a non-boolean term expression evaluates.
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

## Type Lookup Layers

### PNG Object Types

Paramerize [`PnmlNet`](@ref)s & [`AbstractPnmlObject`](@ref)s by [Label Types](@ref).

#### pnmltype\_map
```@example
using PNML # hide
PNML.PnmlTypeDefs.pnmltype_map
```
#### pnmlnet\_type
```@example types
list_type(PNML.pnmlnet_type) # hide
```
#### page\_type
```@example types
list_type(PNML.page_type) # hide
```
#### place\_type
```@example types
list_type(PNML.place_type) # hide
```
#### transition\_type
```@example types
list_type(PNML.transition_type) # hide
```
#### arc\_type
```@example types
list_type(PNML.arc_type) # hide
```

### Label Types

[AbstractLabel](@ref)s are parameterized by [Value Types](@ref).


#### marking\_type
```@example types
list_type(PNML.marking_type) # hide
```
#### condition\_type
```@example types
list_type(PNML.condition_type) # hide
```
#### inscription\_type
```@example types
list_type(PNML.inscription_type) # hide
```
#### refplace\_type
```@example types
list_type(PNML.refplace_type) # hide
```
#### reftransition\_type
```@example types
list_type(PNML.reftransition_type) # hide
```

### Value Types

#### default\_sort\_type
```@example types
list_type(PNML.default_sort_type) # hide
```
#### condition\_value\_type
```@example types
list_type(PNML.condition_value_type) # hide
```
#### inscription\_value\_type
```@example types
list_type(PNML.inscription_value_type) # hide
```
#### marking\_value\_type
```@example types
list_type(PNML.marking_value_type) # hide
```
#### coordinate\_value\_type
```@example types
list_type(PNML.coordinate_value_type) # hide
```
#### term\_value\_type
```@example types
list_type(PNML.term_value_type) # hide
```
#### rate\_value\_type
```@example types
list_type(PNML.rate_value_type) # hide
```
