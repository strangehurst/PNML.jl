# PNML
!!! warning 
	PNML.jl is still a work-in-progress.

[Petri Net Markup Language](https://www.pnml.org), is an XML-based format.
PNML.jl reads a pnml model and emits an intermediate representation (IR).

The intermediate representation (IR) represents the XML tree via dictionaries, with
leaf values including named tuples, LabelledArrays, strings, numbers, objects, vectors.
The tags of the XML are used as keys as much as possible.
 
What is accepted as values is often a superset of what the pntd specifies.
This can be thought of as duck-typing. Conforming to the pntd is not the role of the IR.

# SimpleNet

Created to be a end-to-end use case. And explore implementing something-that-works
while building upon and improving the IR. Does not try to conform to any standard.
Much of the complexity possible with pnml is ignored.

The first use is to recreate the lotka-volterra model from Petri.jl examples.
Find it in the examples folder. This is a stochastic Petri Net.

Liberties are taken with pnml, remember that standards-checking is not a goal.
A less-simple consumer of the IR can impose standards-checking.

# TODO
Features that have not been started:
  - Write pnml file
  - Update pnml model
  - Create pnml model
  - Graphs.jl
  
Features that are not complete:
  - pnml high-level marking, inscription, condition
    * pntd schemas 
	  - specialize where? 
	  - do not highjack tags, only use standard semantics
	* parsing of sort, terms, declarations
	* Symbolics support (is this where PnmlType is useful?)
  - toolspecific usage example


[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://strangehurst.github.io/PNML.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://strangehurst.github.io/PNML.jl/dev)
[![Build Status](https://github.com/strangehurst/PNML.jl/workflows/CI/badge.svg)](https://github.com/strangehurst/PNML.jl/actions)
[![Coverage](https://codecov.io/gh/strangehurst/PNML.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/strangehurst/PNML.jl)
