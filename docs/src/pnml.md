# Petri Net Markup Language

PNML is intended to be an interchange format.

## www.pnml.org

<http://www.pnml.org> has publications and tutorials covering PNML at 
various points in its evolution. Is the cannonical site for the 
RELAX-NG XML schemas that define the grammer of several Petri Net Type Defintions (pntd), 
including:
  - PT Net
  - High-level Place/Transition Net
  - Symmetric Net

These are instances of the 3 flavors supported by PNML.

There are links to a series of ISO/IEC 15909 standards relating to PNML. They cost money.

Note that the people behind PNML appear to be of the Model Driven Engineering (MDE) camp 
and have chosen Java, Eclipse and its EMF. 

The high-level marking, inscription, condition and declaration are where the hard work waits.

See [*A primer on the Petri Net Markup Language and ISO/IEC 15909-2*](https://www.pnml.org/papers/pnnl76.pdf)(pdf)
for more details. The rest of this page will make more sense if you are 
familiar with the primer's contents.


## Interoperability

Pntd is for interchange of pnml models between different tools.
ISO is working on part 3 of the PNML standard covering pntd (as of October 2021).

Petri Net Type Definitions (pntd) are defined using RELAX-NG XML Schema files.
It is possibly to create a non-standard pntd. And more will be standardized, either
formally or informally. Non-standard mostly means that the interchangibility is restricted.

Since validation is not a goal of PNML.jl, non-standard pntds can be used for the 
URI of an XML `net` tag's `type` attribute. Notably `pnmlcore` and `nonstandard` 
are mapped to PnmlCore. 

PnmlCore is the minimum level of meaning that any pnml file can hold. 
PNML.jl should be able to create a valid intermediate representation using PnmlCore,
since all the higher-level meaning is expressed as pnml labels, restrictions,
and required XML tag names.

Further parsing of labels are delegated to some subtype of [`PNML.PetriNet`](@ref).

If you want interchangability of pnml models, you will have to stick to 
the standard pnml pntds. The High Level Petri Net, even when restricted to 
symmetricnet.pntd, is very expressive. Even the base pnmlcore.pntd is useful.

Note that the official pntd schema files are in the grammer directory.

## Why no Schema Verification

Within PNML.jl no schema-level validation is done. 

In is allowed by the PNML specification to omit validation with the presumption that
some specialized, external tool can be applied, thus allowing the file format to be
used for inter-tool communication with lower overhead in each tool.

Also a desire to allow "duck typing" of Petri Nets built upon the 
PNML intermediate representration.

## PNTD

Defaut PNTD to Symbol map keys (URI strings):
```@example
using PNML; foreach(println, sort!(collect(keys(PNML.PnmlTypes.default_pntd_map)))) #hide
```

PnmlType map keys (pntd symbols):
```@example
using PNML; foreach(println, sort!(collect(keys(PNML.PnmlTypes.pnmltype_map)))) #hide
```


## Handling Labels

Labels are expected to have either a <text> element, a <structure> element or both.
Often the <text> is a human-readable representation of of the <structure> element. 
Labels defined in a pntd "require" all meaning to reside in the <structure>.


| PnmlType     | PetriNet       | Description                                            |
| :----------- | :------------- | :------------------------------                        |
| PnmlCore     | ?              | <name> is only defined label                           |
| PTNet        | ?              | initialMarking, inscription labels only have <text>    |
| HLCore       | ?              | support structure used by all HL Petri Net Graphs      |
| PT-HLPNG     | ?              | restrict sort to dot, condition always true            |
| SymmetricNet | ?              | restrict sorts to finite, annotations have <structure> |



## High-level Petri Net Concepts

From the draft version of _ISO/IEC 15909-1:2004 High-level Petri nets - 
Part 1: Concepts, definitions and graphical notation._

Useful for setting the ontology.

Arc inscriptions are expressions that are evaluated.

Place markings are multisets of tokens of a type.

Transition conditions are boolean expressions.

Expressions in _pnml_ can be many-sorted algebras.
Declaration, Term, Sort, Multiset, Variable, are among the concepts 
used to define expressions.


### Terms

Terms have _sort_s: the sort of the variable or the output sort of the operator.

Terms can be buit from built-in *operator*s and *sort*s, and user-defined *variable*s.
These are defined in *variable declaration*s, a kind of
*annotation* label attached to *page*s and *net*s.

A *transition* can have a *condition*, a term of *sort* boolean, 
which imposes restrictions on when the transition may fire.

### Sorts

*named sort*s are constructed from existing *sort*s and given a new name.

*arbitrary sort* is not defined in core, is not allowed in Symmetric Nets. 
HLPNG adds arbitrary declarations, sorts of lists, strings, integers to Symmetric Nets.

The sort of a term is the sort of the *variable* or the output sort of the *operator*.

### Operators

An *operator* can be:
built-in constant, built-in operator, multiset operator or tuple operator.

User-defined operators, or *named operator*s are abbreviations, built from 
existing *operator*s and parameter variables.

There will be arbitrary operator declarations for High-Level Petri Net Graphs, 
but not for Symmetric Nets.

Operators have a sequence of input sorts and a single output sort.

### Variables

__TBD__

### References

See [`PnmlTypes.PnmlType `](@ref), 
[`PnmlTypes.default_pntd_map`](@ref), 
[`PnmlTypes.pnmltype_map`](@ref)
