```@meta
CurrentModule = PNML
```
# Layers of Abstraction

!!! note "Graphics are elided from this discussion"

	Everywhere there are `ToolInfo`s in this discussion one may assume that there
	is also an optional [`Graphics`](@ref) possible.

	While we parse such XML into "containers of strings" and [`Coordinate`](@ref)s.
	No further use is implemented or planned. And no discussion of use is present.

## Intermediate Representation

The intermediate representation (IR) is between the XML model and
a "usable" network. Many different flavors of Petri Nets are expected
to be implemented using the IR.

The IR is constructed by traversing the XML and using tag names as dictonary keys.

In the first part of parsing, a named tuple is filled with appropriate
initial values for each xml tag. Then optional child keys have values bound
as they are parsed.

The second part of parsing instantiates objects using the named tuple as input.

The structure of the IR follows the tree structure of a well-formed XML document
and the PNML specification.

XML attribute names and child element tag names are used for keys
of the same dictonary. The _pnml_ specification/schemas do not use colliding names.
However, the <toolspecific> tag's content is not required to be valid pnml, just
well-formed XML. We assume nobody would use colliding names intentionally.

----

The crude structure required by the pnmlcore schema:
PnmlModel
  - Net
    - Page
    	- Places, Marking
    	- Transitions, Condition
    	- Arcs, Inscription
    	- Toolinfos
    	- Labels
    	- Subpages
    - Name
	- Toolinfos
	- Labels

The IR is implemented under the assumption the the input pnml file is valid.
All tags are assumed to be meaningful to the resulting network.
The pnmlcore schema requires undefined tags will be considered pnml labels.
The IR is capable of handling arbitrary labels.
Many label tags from higherlevel pnml schemas are recognized by the IR parsers.

While the Petri Net Type Definition (pntd) is present in every valid net,
it was not necessary to consult the type during creation of the IR.
It is expected that conforming to pntd will be done at a higher level.

Some parts of pnml are complicated. Not yet completed bits may be implemented
as wrappers holdind unparsed XML. In fact, parts of pnml are specified as holding
any well-formed XML.

----

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
High-level pntds use a `SortType` Term to define expressions as abstract syntax trees in XML.
Intermediate implementation of Terms uses [`DictType`](@ref) to hold the AST.

`default_sort_type(pntd)` returns the type to which a non-boolean term expression evaluates.
Is intended to be used by `Place`s whose markings are multisets of that sort.

| PNTD                  | Sort value        |   |
|-----------------------|-------------------|---|
| PnmlType              | Int               |   |
| AbstractContinuousNet | Float64           |   |
| AbstractHLCore        | eltype(DotSort()) |   |

Note that `eltype(DotSort())` should be `Int`.


Use `Union{Bool, Int, Float64, DictType}` as the set of types that a `Term`'s can contain.
Consider Bool, Int, Float64 as builtin-sorts, and `DictType` as "user defined" sorts.

```@setup types
using  PNML, InteractiveUtils, Markdown
list_type(f) = for pntd in values(PNML.PnmlTypeDefs.pnmltype_map)
    println(rpad(pntd, 15), " -> ", f(pntd))
end

```

## Type Lookup Layers

Petri Net Graph Object Types are parameterized by [Label Types](@ref).
What labels are "allowed" (syntax vs. semantics vs. schema vs. specification)
is parameterized on the PNTD (Petri Net Type Definition).

See [`PnmlNet`](@ref)s & [`AbstractPnmlObject`](@ref)s

#### pnmltype\_map
```@docs; canonical=false
pnmltype_map
```
```@example
using PNML # hide
PNML.PnmlTypeDefs.pnmltype_map
```
#### pnmlnet\_type
```@docs; canonical=false
pnmlnet_type
```
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

#### default\_sort
```@example types
list_type(PNML.default_sort) # hide
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
