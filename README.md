# PNML

[Petri Net Markup Language](https://www.pnml.org), is an XML-based format.
PNML.jl reads a pnml model and emits an intermediate representation (IR).

The intermediate representation (IR) represents the XML tree via julia data structures:
dictionaries, NamedTuples, LabelledArrays, strings, numbers, objects, vectors.
The exact mixture changes as the project continues.

The tags of the XML are used as keys and names as much as possible.
 
What is accepted as values is ~~often~~ usually a superset of what a given pntd schema specifies. This can be thought of as duck-typing. Conforming to the pntd is not the role of the IR. 

The pnml specification has layers.
The core layer is useful and extendable. The standard defines extensions of the core for
place-transition petri nets (integers) and high-level petri net graphs (many-sorted algebra).
This package family adds non-standard continuous net (float64) support. 
Note that there is no RelaxNG schema file for these extensions 

On top of the IR is (will be) implemented Petri Net adaptions and interpertations.
This is the level that pntd conformance can be imposed.
Adaption to julia packages for graphs, agents, and composing into the greater hive-mind. 

Features that have not been started:
  - Write pnml file
  - Update pnml model
  - Create pnml model
  - Graphs.jl
  - Symbolics support for HLPNG (many-sorted algebra)
  
Features that are not complete:
  - HLPNG - many-sorted algebras are complex. Will build other infrastructure...
  - pntd specialize
  - toolspecific usage example

Features that work (perhaps in need of attention as changes are made):
  - continuous petri net (examples/lotka-volterra.jl)
  - pnml core: can read & print all Model Checking Contest (MCC) models

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://strangehurst.github.io/PNML.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://strangehurst.github.io/PNML.jl/dev)
[![Build Status](https://github.com/strangehurst/PNML.jl/workflows/CI/badge.svg)](https://github.com/strangehurst/PNML.jl/actions)
[![Coverage](https://codecov.io/gh/strangehurst/PNML.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/strangehurst/PNML.jl)
