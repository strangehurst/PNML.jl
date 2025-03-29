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

| PNTD                  | Sort value        |   |
|-----------------------|-------------------|---|
| PnmlType              | Int               |   |
| AbstractContinuousNet | Float64           |   |
| AbstractHLCore        | DotConstant())    |   |

Use `Union{Bool, Int, Float64, DictType}` as the set of types that a `Term`'s can contain.
Consider Bool, Int, Float64 as builtin-sorts, and `DictType` as "user defined" sorts.

```@setup types
using  PNML, InteractiveUtils, Markdown
list_type(f) = for pntd in values(PNML.PnmlTypeDefs.pnmltype_map)
    println(rpad(pntd, 15), " -> ", f(pntd))
end
```
```@setup fields
using  PNML, InteractiveUtils, Markdown
list_fields(f) = foreach(println, fieldnames(f))
```

## Data Storage

### Declaration Dictionaries

The net-global storage resides here.

[`DeclDict`](@ref) holds unordered collections indexed by REFID symbol.

```@example fields
list_fields(PNML.DeclDict) # hide
```
The XML file format allows declarations to be declared in <net> and <page> elements.

All [`Declaration`](@ref) labels for a net share the same `DeclDict` as a `ScopedValue`.

XML XPath is used to gather this information before parsing the rest of the elements.
Allows using `DeclDict` while parsing.

### Net Data Dictionaries

This is where the graph node storage resides.

 [`PnmlNetData`](@ref) contains ordered collections of the graph node objects, indexed by REFID symbols.

```@example fields
list_fields(PNML.PnmlNetData) # hide
```

The XML file format distributes a <net> over one or more <page>s. As the pages are parsed,
the nodes are appended to a `PnmlNetData` dictionary and a `PnmlNetKeys` set.

The each `PnmlNetData` dictionary maintains insertion order.

Each graph node may have labels attached.
What labels depends on the [`PnmlTypeDefs`](@ref)

### ID Sets

[`PnmlNetKeys`](@ref) contains ordered sets of REFID symbols.

 ```@example fields
list_fields(PNML.PnmlNetKeys) # hide
```

Each `PnmlNetKeys` set maintains insertion order.

Uses REFIDs to keep track of which page owns which graph nodes or sub-page.
We always use the [`flatten_pages!`](@ref) version.
Testing of non-flattened nets is very minimal.

!!! warning
    After `flatten_pages!` the `PnmlNetKeys` of the only remaining page are assumed to be the same as the `keys` of corresponding `PnmlNetData` dictionary.

## Type Lookup Layers

Petri Net Graph Object Types are parameterized by [Label Types](@ref).
What labels are "allowed" (syntax vs. semantics vs. schema vs. specification)
is parameterized on the PNTD (Petri Net Type Definition).

See [`PnmlNet`](@ref)s & [`AbstractPnmlObject`](@ref)s

#### pnmltype\_map
```@docs; canonical=false
PNML.PnmlTypeDefs.pnmltype_map
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

TBD
