```@meta
CurrentModule = PNML
```

```@contents
Pages = ["interface.md"]
Depth = 5
```
# Interface 

The intermediate representation is used to implement networks 
expressed in a pnml model. The consumer of the IR is a network,
most naturally a varity of Petri Net. 

High-Level Petri Net Graphs can be expressed in a pnml model.

[`PnmlDict`](@ref) is an alias for `Dict{Symbol,Any}`.
Each XML tag is first parsed into a `PnmlDict`, many are then used 
to create higher-level types. Some parts will continue to find 
use for `PnmlDict`'s flexibility.

We start a description of the net IR here. 

## Net & Pages

At the top level a pnml model is one or more networks, 
each described by a <net> tag and one or more <page> tags. 

Pages are present for visual presentation to humans.
Not doing anything with it until convinced there is a viable external community.
Parse for input, worry about writing back out and interchange later.

The collection of pages is flattened before use. Using them unflattened is 
not supposed to be impossible, but is not the arena or the initial use cases:
adapting to use graph tools, catlab, sciml, and other linear algebra things.
See [`flatten_pages!`](@ref).


XML <net> tags are 1st parsed into PnmlDict:

| key          | value description                              |
| :----------- | :--------------------------------------------  |
| tag          | XML tag name is standard in the IR             |
| id           | unique ID                                      |
| name         | text name, optional                            |
| tools        | list of tool specific - possibly empty         |
| labels       | list of generic "pnml labels" - possible empty |
| type         | PnmlType defines schema the XML should meet    |
| declarations | defines high-level semantics of a net          |
| pages        | list of pages - not empty                      |
 
See [`pnml_common_defaults`](@ref), 
[`pnml_node_defaults`](@ref)
and [`parse_net`](@ref) for more detail.

XML <page> tags are also 1st parsed into PnmlDict:

| key          | value description                              |
| :----------- | :--------------------------------------------  |
| tag          | XML tag name is standard in the IR             |
| id           | unique ID                                      |
| name         | text name, optional                            |
| tools        | list of tool specific - possibly empty         |
| labels       | list of generic "pnml labels" - possible empty |
| places       | list of places                                 |
| trans        | list of transitions                            |
| arcs         | list of arcs                                   |
| refP         | references to place on different page          |
| refT         | references to transition on different page     |
| declarations | only net & page tags have declarations         |

See also: [`parse_page`](@ref).

## Petri Net Graphs and Networks

There are 3 top-level forms:
  - [`PetriNet`](@ref) subtpes wraping a single `PnmlNet`, maybe multiple pages.
  - [`PnmlNet`](@ref) assumes there is only 1 page is this net.
  - [`Page`](@ref) when the only page of the only net in a petrinet.

The simplest arrangement is a pnml model with a single <net> element having
a single page. Any <net> may be flatten to a single page. 

The initial `PetriNet` subtypes are built using the assumption that
multiple pages will be flattened to a single page.

```@setup methods
using AbstractTrees, PNML, InteractiveUtils, Markdown
```

## Simple Interface Methods

### pid - access pnml ID symbol

Objects within a pnml graph have unique identifiers,
which are used for referring to the object.
This includes:
[`PnmlObject`](@ref) subtypes,
[`PnmlNet`](@ref).

[`PNML.pid`](@ref)
```@example methods
methods(PNML.pid)
```

### tag - access XML tag symbol


[`PNML.tag`](@ref)
```@example methods
methods(PNML.tag)
```

### has_xml

[`PNML.has_xml`](@ref)
```@example methods
methods(PNML.has_xml)
```

### xmlnode

[`PNML.xmlnode`](@ref)
```@example methods
methods(PNML.xmlnode)
```
### type

[`PNML.type`](@ref)
```@example methods
methods(PNML.type)
```

## Nodes of Graph

[`PNML.places`](@ref)
```@example methods
methods(PNML.places)
```
```@example methods
methods(PNML.transitions)
```
```@example methods
methods(PNML.arcs)
```
```@example methods 
methods(PNML.refplaces) 
```
```@example methods 
methods(PNML.reftransitions) 
```

## Node Predicates

```@example methods 
methods(PNML.has_place) 
```
```@example methods 
methods(PNML.has_transition) 
```
```@example methods
methods(PNML.has_arc)
```
```@example methods 
methods(PNML.has_refP) 
```
```@example methods 
methods(PNML.has_refT) 
```

## Node Vector

```@example methods 
methods(PNML.place) 
```
```@example methods 
methods(PNML.transition)
```
```@example methods
methods(PNML.arc) 
```
```@example methods 
methods(PNML.refplace) 
```
```@example methods 
methods(PNML.reftransition) 
```

## Node ID Vector 

```@example methods 
methods(PNML.place_ids) 
```
```@example methods 
methods(PNML.transition_ids) 
```
```@example methods 
methods(PNML.arc_ids) 
```
```@example methods 
methods(PNML.refplace_ids) 
```
```@example methods 
methods(PNML.reftransition_ids) 
```

## Arc Related

```@example methods 
methods(PNML.all_arcs) 
```
```@example methods 
methods(PNML.src_arcs) 
```
```@example methods 
methods(PNML.tgt_arcs) 
```

```@example methods 
methods(PNML.inscription) 
```

```@example methods 
methods(PNML.deref!) 
```
```@example methods 
methods(PNML.deref_place) 
```
```@example methods 
methods(PNML.deref_transition) 
```

## Place Related

```@example methods 
methods(PNML.marking) 
```
```@example methods 
methods(PNML.initialMarking) 
```

## Transition Related

```@example methods 
methods(PNML.conditions) 
```
```@example methods 
methods(PNML.condition) 
```
```@example methods
methods(PNML.transition_function) 
```
```@example methods
methods(PNML.in_out) 
```

