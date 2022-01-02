# Interface 

The intermediate representation is used to implement networks 
expressed in a pnml model. The consumer of the IR is a network,
most naturally a varity of Petri Net. 

High-Level Petri Net Graphs can be expressed in a pnml model.

#TODO define type for network IR: Wrap a single tag net's [`PnmlDict`](@ref PNML.PnmlDict)?
We start a description of the net IR here. 

## Net & Pages

At the top level a pnml model is described by a single <net> tag
and one or more <page> tags. Pages are present for visual presentation 
to humans. The collection of pages is usually flattened before use.
See [`flatten_page`](@ref PNML.flatten_pages!).

The parsing step for nets & pages converts xml into PnmlDict instances. 
Then constructs objects from the PnmlDict contents.


XML <net> tags are parsed into PnmlDict:

| key          | value description                             |
| :----------- | :-------------------------------------------- |
| tag          | XML tag name is standard in the IR            |
| id           | unique ID                                     |
| name         | text name, optional                           |
| tools        | set of tool specific - possibly empty         |
| labels       | set of generic "pnml labels" - possible empty |
| type         | PnmlType defines schema the XML should meet   |
| declarations | defines high-level semantics of a net         |
| pages        | set of pages - not empty                      |
 
See [`pnml_common_defaults`](@ref PNML.pnml_common_defaults), 
[`pnml_node_defaults`](@ref PNML.pnml_node_defaults)
and [`parse_net`](@ref PNML.parse_net) for more detail.

XML <page> tags are also parsed into PnmlDict:

| key          | value description                             |
| :----------- | :-------------------------------------------- |
| tag          | XML tag name is standard in the IR            |
| id           | unique ID                                     |
| name         | text name, optional                           |
| tools        | set of tool specific - possibly empty         |
| labels       | set of generic "pnml labels" - possible empty |
| places       | set of places                                 |
| trans        | set of transitions                            |
| arcs         | set of arcs                                   |
| refP         | references to place on different page         |
| refT         | references to transition on different page    |
| declarations | only net & page tags have declarations        |

See also: [`parse_page`](@ref PNML.parse_page).

__TBD__


## Methods

pid
tag

