#
```@meta
CurrentModule = PNML
```

Based on a draft version of _ISO/IEC 15909-1:2004 High-level Petri nets - Part 1:
Concepts, definitions and graphical notation._

Useful for setting the ontology.

Arc inscriptions are expressions that are evaluated.

Place markings are multisets of tokens of a sort/type.

Transition conditions are boolean expressions that are evaluated.
Used to determine if transition is enabled.

Expressions in _pnml_ can be many-sorted algebras.
Declaration, Term, Sort, Multiset, Variable, are among the concepts
used to define expressions.


## Terms

Terms have *sort*s: the sort of the variable or the output sort of the operator.

Terms can be buit from built-in *operator*s and *sort*s, and user-defined *variable*s.
These are defined in *variable declaration*s, a kind of *annotation* label attached to *page*s and *net*s.

A *transition* can have a *condition*, a term of *sort* boolean,
which imposes restrictions on when the transition may fire.

## Sorts

*named sort*s are constructed from existing *sort*s and given a new name.

*arbitrary sort* is not defined in core, is not allowed in *Symmetric Nets*.
HLPNG adds *arbitrary declarations*, sorts of *lists*, *strings*, *integers* to *Symmetric Nets*.

The sort of a term is the sort of the *variable* or the output sort of the *operator*.

## Operators

An *operator* can be:
built-in constant, built-in operator, multiset operator or tuple operator.

User-defined operators, or *named operator*s are abbreviations, built from
existing *operator*s and parameter variables.

There will be arbitrary operator declarations for High-Level Petri Net Graphs,
but not for Symmetric Nets.

Operators have a sequence of input sorts and a single output sort.

## Variables

__TBD__



## Notes on Petri Nets

### Multiset Rewriting Systems

I. Cervesato: [Petri Nets as Multiset Rewriting Systems in a Linear Framework](https://citeseerx.ist.psu.edu/document?repid=rep1&type=pdf&doi=d5e629e53d831d63d04ac1520e7f7774273488b8)

This addresses Place Transition Nets. High-level Petri nets explictily use multisets.

> factor out the multiplicity of the elements of the underlying set. This is achieved by first defining the notion of singleton multisets and then by writing arbitrary multisets as linear combination of singleton multisets.

> a rewrite rule can be viewed as a singleton multiset

> Petri nets are meant to represent evolving systems. To represent this dynamic flavor, we will rely on the notion of multiset rewriting systems.



## Continuous, Open and Other Petri Nets

Allow marking, inscription, conditions to be floating point even when standard
wants an integer. This allows continuous nets.

See [Petri.jl](https://github.com/mehalter/Petri.jl)
and [AlgebraicPetri.jl](https://github.com/AlgebraicJulia/AlgebraicPetri.jl)
for some continuous Petri Net use-cases.

TODO: Hybrid nets combining floating point/continuous and integer/discrete
inscription/marking.
