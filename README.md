# PNML
PNML.jl is still a work-in-progress.

[Petri Net Markup Language](https://www.pnml.org) is an XML-based format.
PNML.jl reads a pnml model and emits an intermediate representation. 

Petri Net Type Definitions (pntd) are defined using RelaxNG XML Schema files.
It is possibly to create a non-standard pntd. Since validation is not a goal,
non-standard pntds can be used.

Note that ISO is working on part 3 of the PNML standard covering pntd (October 2021).

The intermediate representation (IR) represents the XML tree via names tuples,
dictonaries, LabelledArrays. The tags of the XML are used as keys as much as possible.
 
What is accepted as values is often a superset of what the pntd specifies.
This can be thought of as duck-typing. Conforming to the pntd is not the role of the IR.

# SimpleNet

Created from the IR, only the first page of the first net is used 
and much of the complexity possible with pnml is ignored.

The first use case is to recreate the lotka-volterra model from Petri.jl.

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://strangehurst.github.io/PNML.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://strangehurst.github.io/PNML.jl/dev)
[![Build Status](https://github.com/strangehurst/PNML.jl/workflows/CI/badge.svg)](https://github.com/strangehurst/PNML.jl/actions)
[![Coverage](https://codecov.io/gh/strangehurst/PNML.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/strangehurst/PNML.jl)
