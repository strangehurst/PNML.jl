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

See [`PnmlTypeDefs`](@ref) module page.

There are levels:  Core (Place-Transition), Continuous and High-Level PNG (HLPNG).

[`PnmlCoreNet`](@ref) is a concrete subtype of [`PnmlType`](@ref).
`PnmlCoreNet` is used by some `AbstractPetriNet` concrete types ([`SimpleNet`](@ref)).

[`ContinuousNet`](@ref) is a concrete type of [`AbstractContinuousNet`](@ref).
`ContinuousNet` uses floating point marking and inscriptions.
It is a nonstandard extension to the ISO specification.

[`HLCoreNet`](@ref) is a concrete subtype of [`AbstractHLCore`](@ref).
`HLCoreNet` is used by some `AbstractPetriNet` concrete types ([`HLPetriNet`](@ref)).
Think of it as a testable implementation of `AbstractHLCore`.

The IR does not try to impose semantics on the model. Those semantics should
be part of [`AbstractPetriNet`](@ref).  The IR tries to represent the model (all models)
at a structural level. It may paramertize types to facilitate specilization.

```@example type
type_tree(PNML.PnmlTypeDefs.PnmlType) # hide
```

| PnmlType     | Description                                               |
| :---------   | :-------------------------------------------------------- |
| PnmlCoreNet  | <name> is only defined label                              |
| PTNet        | <initialMarking>, <inscription> labels only have <text>   |
| HLCoreNet    | support structure used by all HL Petri Net Graphs         |
| PT-HLPNG     | restrict sort to dot, condition always true               |
| SymmetricNet | restrict sorts to finite, annotations have <structure>    |
| HLNet        | extend symmetric with arbitrary sorts                     |
| Stochastic   | continuous or discrete                                    |
| Timed        | continuous or discrete                                    |
| Open         | continuous or discrete                                    |

Todo: Continuous Petri Net

| Full Name     | Node       | Label Description                                   |
|:--------------|:-----------|:----------------------------------------------------|
| Marking       | Place      |                                                     |
| Inscription   | Arc        |                                                     |
| HLMarking     | Place      |                                                     |
| HLInscription | Arc        |                                                     |
| Condition     | Transition |                                                     |
| Rate          | Transition | random variable or function of marking, firing rate |
| Priority      | Transition | firing order of enabled transitions                 |
| Weight        | Transition | firing tiebreaker                                   |

Note that *Rate*, *Priority* and *Weight* are not part of base specification.
See [Unclaimed Labels](@ref)

## AbstractPetriNet
[`AbstractPetriNet`](@ref) uses the Intermediate Representation's
[`PnmlNet`](@ref) and `PnmlType` to implement a Petri Net Graph (PNG).

```@example type
type_tree(PNML.AbstractPetriNet) # hide
```

## AbstractPnmlObject
[`Page`](@ref), [`Arc`](@ref), [`Place`](@ref), [`Transition`](@ref) define the graph of a [`PnmlNet`](@ref).

```@example type
type_tree(PNML.AbstractPnmlObject) # hide
```

Fields expected of every subtype of [`AbstractPnmlObject`](@ref):

| Name     | Type |
|:---------|:-----------------------------------|
| id       | Symbol |
| pntd     | <: PnmlType |
| name     | Maybe{Name} |
| labels   | PnmlLabel |
| tools    | ToolInfo |

## AbstractLabel
[`AbstractLabel`](@ref)s are attached to `AbstractPnmlObject`s.
Kinds of label include: marking, inscription, condition and declarations, sort, and ad-hoc.
Ad-hoc is where we assume any undefined element attached to a `AbstractPnmlObject` instance
is a label and add it to a collection of 'other labels'.
Some 'other labels' can be accessed using: [`rate`](@ref), [`delay`](@ref).

```@example type
type_tree(PNML.AbstractLabel) # hide
```

!!! info "Difference between Object and Label"

	- Objects have *id*s and `Name`s.
    - Labels are attached to Objects.
    - Some Labels (attributes) do not have `Graphics`.
    - Labels are extendable.
    - Labels are named by the xml tag. Any "unknown" tag of an Object is presumed to be a label.

## AbstractPnmlTool
See [`ToolInfo`](@ref).
```@example type
type_tree(PNML.AbstractPnmlTool) # hide
```
## PnmlException
```@example type
type_tree(PNML.PnmlException) # hide
```

# Many-sorted Algebra Concepts

The PNML Specification builds the High-level Petri Net Graph as a layer using a Core layer (PnmlCore). The main feature of the HL layer (HLCore) is to require all annotation labels to have <text> and <structure> elements. All meaning is required to reside in a single child of <structure>. With the <text> for human/documentation use.

Implemented so that it is mostly part of the PnmlCore implementation.
At which level, both <text> and <structure> are optional.

The <type> label of a [`Place`](@ref) is meant to be a _sort_ of a _many-sorted algebra_.
We call it _sorttype_ to reduce the confusion.

PNML.jl allows/requires all net type's places to have _sorttype_ objects. Only high-level PNML input is expected to contain a <type> tag. For other nets we interpret the [`SortType`](@ref) to be [`IntegerSort`](@ref) or [`RealSort`](@ref) based on PNTD. And [`Marking`](@ref) values of non-high-level nets are interpreted as multisets with airity of 1.
This allows more common implementation in the core layer.

For high-level nets the sorttype object is an [`SortType`](@ref) `HLAnnotation`
subtype containing an [`AbstractSort`](@ref).

## AbstractDeclaration

Labels attached to [`PnmlNet`](@ref) and/or [`Page`](@ref).
The [`Declaration`](@ref)s contained in a <declarations> apply to the whole net even when attached to a `Page`.
```@example type
type_tree(PNML.AbstractDeclaration) # hide
```
## AbstractSort
Each `Place` has a sorttype containing an `AbstractSort`.
```@example type
type_tree(PNML.AbstractSort) # hide
```
## AbstractTerm
Part of the *many-sorted algebra* of a High-level net.
See [`AbstractOperator`](@ref). [`Variable`](@ref)
```@example type
type_tree(PNML.AbstractTerm) # hide
```
