```@meta
CurrentModule = PNML
```

Overview of some type hierarchies.

```@setup type
using AbstractTrees, PNML, InteractiveUtils, Markdown
#, GraphRecipes,Plots

AbstractTrees.children(x::Type) = subtypes(x)
type_tree(t) = println(AbstractTrees.repr_tree(t))
```
## PnmlType - Petri Net Type Definition
See [PnmlTypes](@ref) module page.

There are levels:  Core (Place-Transition), Continuous and High-Level PNG.

[`PnmlCore`](@ref) is a concrete subtype of [`PnmlType`](@ref).
`PnmlCore` is used by some `PetriNet` concrete types ([`SimpleNet`](@ref)).

[`ContinuousNet`](@ref) uses floating point marking and inscriptions.
It is an extension to the ISO specification.

[`HLCore`](@ref) is a concrete subtype of [`AbstractHLCore`](@ref).
`HLCore` is used by some `PetriNet` concrete types ([`HLPetriNet`](@ref)).
Think of it as a testable implementation of `AbstractHLCore`.

The IR does not try to impose semantics on the model. Those semantics should
be part of [`PetriNet`](@ref).  The IR tries to represent the model (all models)
at a structural level. It may paramertize types to facilitate specilaization.

```@example type
type_tree(PNML.PnmlTypes.PnmlType) # hide
```

| PnmlType     | Place | Trans | Arc  | Description                                               |
| :---------   | :---- | :---- | :--- | :-------------------------------------------------------- |
| PnmlCore     |       |       |      | <name> is only defined label                              |
| PTNet        | PTM   | none  | PTI  | <initialMarking>, <inscription> labels only have <text>   |
| HLCore       | HLM   | Cond  | HLI  | support structure used by all HL Petri Net Graphs         |
| PT-HLPNG     | HLM   | Cond  | HLI  | restrict sort to dot, condition always true               |
| SymmetricNet | HLM   | Cond  | HLI  | restrict sorts to finite, annotations have <structure>    |
| HLNet        | HLM   | Cond  | HLI  | extend symmetric with arbitrary sorts                     |
| Stochastic   |       | Rate  |      | continuous or discrete                                    |
| Timed        |       |       |      | continuous or discrete                                    |
| Open         |       |       |      | continuous or discrete                                    |

Todo: Continuous Petri Net

| Abbreviation | Full Name     | Node       | Label Description                                   |
|:-------------|:--------------|:-----------|:----------------------------------------------------|
| PTM          | PTMarking     | Place      |                                                     |
| PTI          | PTInscription | Arc        |                                                     |
| HLM          | HLMarking     | Place      |                                                     |
| HLI          | HLInscription | Arc        |                                                     |
| Cond         | Condition     | Transition |                                                     |
| Rate         | Rate          | Transition | random variable or function of marking, firing rate |
| Pri          | Priority      | Transition | firing order of enabled transitions                 |
| We           | Weight        | Transition | firing tiebreaker                                   |
|              |               |            |                                                     |


## PetriNet
[`PetriNet`](@ref) uses the Intermediate Representation and `PnmlType` to implement a petri Net Graph.

```@example type
type_tree(PNML.PetriNet) # hide
```

## PnmlObject
Page, Arc, Place, Transition define the graph of a petri net.
```@example type
type_tree(PNML.PnmlObject) # hide
```
## AbstractLabel
Labels are attached to `PnmlObject`s. 
Kinds of label include: marking, inscription, condition and 
declarations of sorts, operators, and variables.
```@example type
type_tree(PNML.AbstractLabel) # hide
```

!!! info "Difference between Object and Label"

	- Objects have *id*s and `Name`s.
    - Labels are attached to Objects.
    - Some Labels (attributes) do not have `Graphics`.
    - Labels are extendable.
    - Labels are named by the xml tag. Any "unknown" tag is presumed to be a label.

## AbstractPnmlTool
See [`ToolInfo`](@ref).
```@example type
type_tree(PNML.AbstractPnmlTool) # hide
```
## PnmlException
```@example type
type_tree(PNML.PnmlException) # hide
```
## AbstractDeclaration
Labels attached to [`PnmlNet`](@ref) and/or [`Page`](@ref).
```@example type
type_tree(PNML.AbstractDeclaration) # hide
```
## AbstractSort
High-level net's `Place` has a sort. 
```@example type
type_tree(PNML.AbstractSort) # hide
```
## AbstractTerm 
Part of the *many-sorted algebra* of a High-level net.
```@example type
type_tree(PNML.AbstractTerm) # hide
```
