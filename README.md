# PNML

[Petri Net Markup Language](https://www.pnml.org), is an XML-based format.
PNML.jl reads a pnml model and emits an intermediate representation (IR).

Features that have not been started:
  - Write pnml file
  - Update pnml model
  - Create pnml model
  - Symbolics support for HLPNG (many-sorted algebra)
  
Features that are not complete:
  - HLPNG - many-sorted algebras are complex. Will build other infrastructure...
  - pntd specialize
  - toolspecific usage example

Features that work (perhaps in need of attention as changes are made):
  - stochastic petri nets (examples/lotka-volterra.jl) via rate labels for transitions.
  - pnml core: can read & print Model Checking Contest (MCC) models, abet with some warnings due to incomplete implementation.
  - MetaGraphNext.SimpleDiGraphFromIterator used to create a graph with labels.

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://strangehurst.github.io/PNML.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://strangehurst.github.io/PNML.jl/dev)
[![Build Status](https://github.com/strangehurst/PNML.jl/workflows/CI/badge.svg)](https://github.com/strangehurst/PNML.jl/actions)
[![Coverage](https://codecov.io/gh/strangehurst/PNML.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/strangehurst/PNML.jl)
