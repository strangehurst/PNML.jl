# Interface 

The intermediate representation is used to implement networks 
expressed in a pnml model. The consumer of the IR is a network,
most naturally a varity of Petri Net. 

High-Level Petri Net Graphs can be expressed in a pnml model.

[`PnmlDict`](@ref PNML.PnmlDict) is an alias for `Dict{Symbol,Any}`.
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
See [`flatten_page!`](@ref PNML.flatten_pages!).


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
 
See [`pnml_common_defaults`](@ref PNML.pnml_common_defaults), 
[`pnml_node_defaults`](@ref PNML.pnml_node_defaults)
and [`parse_net`](@ref PNML.parse_net) for more detail.

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

See also: [`parse_page`](@ref PNML.parse_page).




## Methods

```@setup methods
using AbstractTrees, PNML, InteractiveUtils, Markdown

```
```@example methods
methods(PNML.pid)
```
```@example methods
methods(PNML.tag)
```
```@example methods
methods(PNML.has_xml)
```
```@example methods
methods(PNML.xmlnode)
```
```@example methods
methods(PNML.type)
```
```@example methods
methods(PNML.places)
```
```@example methods
methods(PNML.transitions)
```
```@example methods
methods(PNML.arcs)
```


