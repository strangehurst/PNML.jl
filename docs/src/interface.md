```@meta
CurrentModule = PNML
```

```@contents
Pages = ["interface.md"]
Depth = 5
```
# Interface

!!! warning
    Being a work in progress, there will be obsolete, optimistic or incoherent bits.

    Eventually this section will cover interfaces in a useful way.

The intermediate representation is used to implement networks
expressed in a pnml model. The consumer of the IR is a network,
most naturally a varity of Petri Net.

High-Level Petri Net Graphs (HLPNG) can be expressed in a pnml model.

We start a description of the net IR here.

## PnmlDict or NamedTuple

Switch from `PnmlDict`, a dictionary over `{Symbol,Any}` to `NamedTuple`s.
There are pnml IDs and XML element tag names are used as names.

Each XML tag is first parsed (recursivly) into a named tuple, with tags as the names,
then tuple is used to create higher-level types.

Wraps a `NamedTuple`:
  * [`AnyElement`](@ref)
  * [`PnmlLabel`](@ref)
  * [`Sort`](@ref)
  * [`Term`](@ref)

## Top Level: Model, Net, Page

At the top level[^layers] a <pnml> model is one or more networks::[`PnmlNet`](@ref),
each described by a <net> tag and one or more <page> tags.

[`Page`](@ref)
 is a required element mostly present for visual presentation to humans.
It contains [`AbstractPnmlObject`](@ref) types that implement the Petri Net Graph (PNG).

[^layers]:
    `Page` inside a `PnmlNet` inside a `AbstractPetriNet`.
    Where the Petri Net part is expressed as a Petri Net Type Definition XML schema
    file (.pntd) identified by a URI. Or would if our nonstandard extensions had schemas
    defined. Someday there will be such schemas.

[`ObjectCommon`](@ref) is a field of most types.
This allows `Graphics` and `ToolInfo` to appear almost anywhere in the PNG.

While [`Graphics`](@ref) is implemented as part of `ObjectCommon`
it is not dicussed further (until someone extends/uses it).

`ObjectCommon`  also has [`ToolInfo`](@ref) used to attach well-formed XML.
TODO: Need way to parse <toolspecific> that is flexible/extendable.

Parse pnml for input, worry about writing back out and interchange later (future extensions).
Another future extension may be to use pages for distributed computing.

The pnml specification permits that multiple pages to be flattened
(by [`flatten_pages!`](@ref)) to a single `Page` before use.
Using them unflattened is not supposed to be impossible,
but is not the arena or the initial use cases (in no paticular order):
adapting to use graph tools, agent based modeling, sciml, etc.

[`AbstractPetriNet`](@ref) subtypes wrap and extend [`PnmlNet`](@ref).
Note the **Pnml** to **Petri**.



`PnmlNet` and its contents can be considered an intermediate representation (IR).
A concrete `AbstractPetriNet` type uses the IR to produce higher-level behavior.
This is the level at which [`flatten_pages!`](@ref) and [`deref!`](@ref) operate.

`AbstractPetriNet` is the level of most Petri Net Graph semantics.
One example is enforcing integer, non-negative, positive.
One mechanism used is type parameters.

Remember, the IR trys to be as promiscuous as possible.

XML <net> tags are 1st parsed into `NamedTuple`
which is used by [`parse_net`](@ref) to construct a [`PnmlNet`](@ref):

| key          | value description                              |
| :----------- | :--------------------------------------------  |
| tag          | XML tag symbol `:net`                          |
| id           | unique ID                                      |
| name         | text name, optional                            |
| tools        | list of tool specific - possibly empty         |
| labels       | list of generic "pnml labels" - possible empty |
| type         | PnmlType defines schema the XML should meet    |
| declarations | defines high-level semantics of a net          |
| pages        | list of pages - not empty                      |

XML <page> tags are also 1st parsed by [`parse_page!`](@ref) into `NamedTuple`
which is used to construct a [`Page`](@ref):

| key          | value description                              |
| :----------- | :--------------------------------------------  |
| tag          | XML tag symbol `:page`                         |
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
| pages        | pages can be nested                            |

## Places

Properties that various places may have one or more of:
  * discrete
  * continuous
  * timed

## Transitions

Properties that various transitions may have one or more of:
  * discrete
  * continuous
  * hybrid of discrete & continuous subnets
  * stochastic
  * immediate
  * deterministically time delayed
  * scheduled

The pnml schemas and primer only try to cover the discrete case as Place-Transition and High-Level Petri Nets.
With a lot of multi-sorted algebra to make High-Level Nets complicated enough to be challenging.

Continous support is present where possible. For instance, when a number appers in the XML
[`number_value`](@ref) is used to parse the string to `Int` or `Float64`.
This is currently (2022) "non-standard" so such pnml files will not be generally
interchangable with other tools.


['Discrete, Continuous, and Hybrid Petri Nets' by Rene David and Hassane Alla](https://link.springer.com/book/10.1007/978-3-642-10669-9)

[VANESA](https://www.sciencedirect.com/science/article/pii/S0303264721001714#b8)

See [`rate`](@ref) for a use of non-standard labels by [`SimpleNet`](@ref).
Implements a continuous petri net as part of the first working use-case.
Demonstrates the expressiveness of pnml.

## Petri Net Graphs and Networks

There are 3 top-level forms:
  - [`AbstractPetriNet`](@ref) subtypes wraping a single `PnmlNet`.
  - [`PnmlNet`](@ref)  maybe multiple pages.
  - [`Page`](@ref) when the only page of the only net in a Abstractpetrinet.

The simplest arrangement is a pnml model with a single <net> element having
a single page. Any <net> may be flatten to a single page.

The initial `AbstractPetriNet` subtypes are built using the assumption that
multiple pages will be flattened to a single page.

```@setup methods
using AbstractTrees, PNML, InteractiveUtils, Markdown
```

## Simple Interface Methods

### pid - get PNML ID symbol

Objects within a pnml graph have unique identifiers,
which are used for referring to the object.
This includes:
[`AbstractPnmlObject`](@ref) subtypes,
[`PnmlNet`](@ref).

[`PNML.pid`](@ref)
```@example methods
methods(PNML.pid) # hide
```

### name - get name

`AbstractPnmlObject`s and `PnmlNet`s have a name label.
[`Declaration`](@ref)s have a name attribute.
[`ToolInfo`](@ref)s have a toolname attribute.

[`PNML.name`](@ref)
```@example methods
methods(PNML.name) # hide
```

### tag - access XML tag symbol

[`PNML.tag`](@ref)
```@example methods
methods(PNML.tag) # hide
```

### has\_xml - is xml attached

[`PNML.has_xml`](@ref)
```@example methods
methods(PNML.has_xml) # hide
```

### xmlnode - access xml

[`PNML.xmlnode`](@ref)
```@example methods
methods(PNML.xmlnode) # hide
```

### nettype - return PnmlType identifying PNTD

[`PNML.nettype`](@ref)
```@example methods
methods(PNML.nettype) # hide
```

## Nodes of Petri Net Graph

Return vector of nodes.

### places
[`PNML.places`](@ref)
```@example methods
methods(PNML.places) # hide
```
### transitions
[`PNML.transitions`](@ref)
```@example methods
methods(PNML.transitions) # hide
```
### arcs
[`PNML.arcs`](@ref)
```@example methods
methods(PNML.arcs) # hide
```
### refplaces
[`PNML.refplaces`](@ref)
```@example methods
methods(PNML.refplaces)  # hide
```
### reftransitions
[`PNML.reftransitions`](@ref)
```@example methods
methods(PNML.reftransitions)  # hide
```

## Node Predicates - uses PNML ID

### has\_place
[`PNML.has_place`](@ref)
```@example methods
methods(PNML.has_place)  # hide
```
### has\_transition
[`PNML.has_place`](@ref)
```@example methods
methods(PNML.has_transition)  # hide
```
### has\_arc
[`PNML.has_arc`](@ref)
```@example methods
methods(PNML.has_arc) # hide
```
### has\_refP
[`PNML.has_refP`](@ref)
```@example methods
methods(PNML.has_refP)  # hide
```
### has\_refT
[`PNML.has_refT`](@ref)
```@example methods
methods(PNML.has_refT)  # hide
```

## Node Access - uses PNML ID

### place
[`PNML.place`](@ref)
```@example methods
methods(PNML.place)  # hide
```
### transition
[`PNML.transition`](@ref)
```@example methods
methods(PNML.transition) # hide
```
### arc
[`PNML.arc`](@ref)
```@example methods
methods(PNML.arc)  # hide
```
### refplace
[`PNML.refplace`](@ref)
```@example methods
methods(PNML.refplace)  # hide
```
### reftransition
[`PNML.reftransition`](@ref)
```@example methods
methods(PNML.reftransition)  # hide
```

## Node ID Vector

### place\_ids
[`PNML.place_ids`](@ref)
```@example methods
methods(PNML.place_ids)  # hide
```
### transition\_ids
[`PNML.transition_ids`](@ref)
```@example methods
methods(PNML.transition_ids)  # hide
```
### arc\_ids
[`PNML.arc_ids`](@ref)
```@example methods
methods(PNML.arc_ids)  # hide
```
### refplace\_ids
[`PNML.refplace_ids`](@ref)
```@example methods
methods(PNML.refplace_ids)  # hide
```
### reftransition\_ids
[`PNML.reftransition_ids`](@ref)
```@example methods
methods(PNML.reftransition_ids)  # hide
```

## Arc Related

### all\_arcs - source or target is PNML ID
[`PNML.all_arcs`](@ref)
```@example methods
methods(PNML.all_arcs)  # hide
```
### src\_arcs - source is PNML ID
[`PNML.src_arcs`](@ref)
```@example methods
methods(PNML.src_arcs)  # hide
```
### tgt\_arcs - target is PNML ID
[`tgt_arcs`](@ref)
```@example methods
methods(PNML.tgt_arcs)  # hide
```
### inscription - evaluate inscription value (or return default)
[`inscription`](@ref)
```@example methods
methods(PNML.inscription)  # hide
```
### deref! - dereference all references of flattened net
[`deref!`](@ref)
```@example methods
methods(PNML.deref!)  # hide
```
### deref\_place - dereference one place
[`deref_place`](@ref)
```@example methods
methods(PNML.deref_place)  # hide
```
### deref\_transition - dereference one transition
[`deref_transition`](@ref)
```@example methods
methods(PNML.deref_transition)  # hide
```

## Place Related

### marking - evaluate marking value (or return default)
[`marking`](@ref)
```@example methods
methods(PNML.marking)  # hide
```
### initialMarking -
[`initialMarking`](@ref)
```@example methods
methods(PNML.initialMarking)  # hide
```

## Transition Related

### conditions - collect evaluated conditions
[`conditions`](@ref)
```@example methods
methods(PNML.conditions)  # hide
```
### condition - evaluate condition of one transition
[`condition`](@ref)
```@example methods
methods(PNML.condition)  # hide
```
### transition\_function - return `LVector` of `in_out` for all transitions
[`transition_function`](@ref)
```@example methods
methods(PNML.transition_function)  # hide
```
### in\_out - tuple of `ins`, `outs` of one transition
[`in_out`](@ref)
```@example methods
methods(PNML.in_out)  # hide
```

### ins - `LVector` of source arc evaluated inscriptions.
[`ins`](@ref)
```@example methods
methods(PNML.ins)  # hide
```

### outs - `LVector` of target arc evaluated inscriptions.
[`outs`](@ref)
```@example methods
methods(PNML.outs)  # hide
```

## Labels - `Annotation` and `HLAnnotation`

Both have `ObjectCommon`. [`HLAnnotation`](@ref) adds optional <text>, <structure>.

### has\_text
[`has_text`](@ref)
```@example methods
methods(PNML.has_text) # hide
```

### has\_structure
[`has_structure`](@ref)
```@example methods
methods(PNML.has_structure) # hide
```

### text
[`text`](@ref)
```@example methods
methods(PNML.text) # hide
```

### structure
[`structure`](@ref)
```@example methods
methods(PNML.structure) # hide
```

### has_labels - do any exist
[`has_labels`](@ref)
```@example methods
methods(PNML.has_labels) # hide
```

### has_label - does a specific label exist
[`has_label`](@ref)
```@example methods
methods(PNML.has_label) # hide
```

### get_label - get a specific label
[`get_label`](@ref)
```@example methods
methods(PNML.get_label) # hide
```

## ToolInfo

### has_toolinfo - does a specific toolinfo exist
[`has_toolinfo`](@ref)
```@example methods
methods(PNML.has_toolinfo) # hide
```
### get_toolinfo - get a specific toolinfo exist
[`get_toolinfo`](@ref)
```@example methods
methods(PNML.get_toolinfo) # hide
```

## PnmlType traits

See [`PnmlTypeDefs`](@ref) for details of the module.

## _evaluate, functors, markings,  inscriptions

[`_evaluate`](@ref)
```@example methods
methods(PNML._evaluate) # hide
```

[`default_marking`](@ref)
```@example methods
methods(PNML.default_marking) # hide
```

[`default_inscription`](@ref)
```@example methods
methods(PNML.default_inscription) # hide
```

[`default_condition`](@ref)
```@example methods
methods(PNML.default_condition) # hide
```
[`default_one_term`](@ref)
```@example methods
methods(PNML.default_one_term) # hide
```

Things that are functors:
  - Marking: return `Int`, `Float64`, or `Term`
  - Inscription: return `Int`, `Float64`, or `Term`
  - Condition: return `Int`, `Float64`, or `Term`
  - Term: return a sort's value

Defaults
  - markings: return zero(`Int`), zero(`Float64`), or default_zero_term
  - inscription: return one(`Int`), one(`Float64`), or default_one_term
  - condition: return `true`, or boolean sort's true value
  - Term: return boolean sort's true value
