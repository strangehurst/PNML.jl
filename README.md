# PNML

[Petri Net Markup Language](https://www.pnml.org), is an XML-based format.
PNML.jl reads a pnml model and emits an intermediate representation (IR).

The intermediate representation (IR) represents the XML tree via julia data structures:
dictionaries, NamedTuples, LabelledArrays, strings, numbers, objects, vectors.
The exact mixture changes as the project continues.

The tags of the XML are used as keys and names as much as possible.
 
What is accepted as values is often a superset of what the pntd schema specifies.
This can be thought of as duck-typing. Conforming to the pntd is not the role of the IR.

On top of the IR is (will be) implemented Petri Net adaptions and interpertations.
This is the level that pntd conformance can be imposed.
Adaption to julia packages for graphs, agents, and composing into the greater hive-mind. 

# TODO

Features that have not been started:
  - Write pnml file
  - Update pnml model
  - Create pnml model
  - Graphs.jl
  
Features that are not complete:
  - pnml high-level marking, inscription, condition
    * pntd schemas- specialize where? 
	* Symbolics support (is this where PnmlType is useful?)
  - toolspecific usage example


[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://strangehurst.github.io/PNML.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://strangehurst.github.io/PNML.jl/dev)
[![Build Status](https://github.com/strangehurst/PNML.jl/workflows/CI/badge.svg)](https://github.com/strangehurst/PNML.jl/actions)
[![Coverage](https://codecov.io/gh/strangehurst/PNML.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/strangehurst/PNML.jl)
