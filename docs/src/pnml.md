```@meta
CurrentModule = PNML
```

# PNML.jl

Documentation for the GitHub [PNML.jl](https://github.com/strangehurst/PNML.jl) repository.
Which defines a Julia module named `PNML`.
Which handles an XML markup language with the acronym 'PNML' -- [Petri Net](https://en.wikipedia.org/wiki/Petri_net) Markup Language.

```@eval
using Markdown, Pkg, Dates, InteractiveUtils

function print_dep_version(depname)
	deps = values(Pkg.dependencies())
	version = first(d for d in deps if d.name == depname).version
	"$depname: v$version"
end

Markdown.parse("""
	These docs were generated at $(now()) on $(gethostname()) using:
		- $(print_dep_version("PNML"))
   """)
```

```@repl
using InteractiveUtils; # hide
versioninfo()
```

## www.pnml.org

In this section 'PNML' refers to the markup language, its specification and schemas, not this software.

<http://www.pnml.org>
  - has publications and tutorials covering PNML at various points in its evolution.
  - has links to a series of ISO/IEC 15909 standards relating to PNML.
  - is the cannonical site for the meta-models, RELAX-NG XML schemas that define the grammar of several Petri Net Type Defintions (pntd), including:
	  - PT Net (Place/Transition Net)
	  - Symmetric Net
  - and more: examples, meta-models in EMF, java-based framework

There are 2 flavors currently covered by PNML meta-models:
  - integer-valued, where tokens have collective identities.
  - High-level, where tokens have individual identities using a many-sorted algebra.

The people behind PNML, and as stated in _15909-2_, are of the Model Driven Software Engineering camp and have chosen Java, Eclipse and its modeling framework (EMF).

See [*A primer on the Petri Net Markup Language and ISO/IEC 15909-2*](https://www.pnml.org/papers/pnnl76.pdf)(pdf) for more details. The rest of this page will hopefully make more sense if you are familiar with the primer's contents. Use the RelaxNG Schema as definitive like the 'primer' counsels.

Note that the pnml XML file is the working intermediate representation of a suite of tools that use
RelaxNG and Schematron for validation of the interchange file's content.

## Interoperability

Petri Net Type Definition schema files (pntd) are defined using RELAX-NG XML Schema files (rng).
Petri Net Markup Language files (pnml) are intended to be validated against a pntd schema.

For interchange of pnml between tools it should be enough to support the same pntd schema.

Note that ISO released part 3 of the PNML standard covering extensions and structuring mechanisms in 2021. And some http://www.pnml.org files address these extensions.

It is possible to create a non-standard pntd. And more will be standardized, either
formally or informally. Non-standard mostly means that the interchangibility is restricted.

Since validation is not a goal of PNML.jl, non-standard pntds can be used for the
URI of an XML `net` tag's `type` attribute. Notably `pnmlcore` and `nonstandard`
are mapped to [`PnmlCoreNet`](@ref).

`PnmlCoreNet` is the minimum level of meaning that any pnml file can hold.
PNML.jl should be able to create a valid intermediate representation using `PnmlCoreNet`
since all the higher-level meaning is expressed as pnml labels, restrictions,
and required XML tag names.

Further parsing of labels is specialized upon subtypes of [`PNML.AbstractPetriNet`](@ref).
See [Traits](@ref) for more details.

If you want interchangability of pnml models, you will have to stick to
the standard pnml pntds. The High Level Petri Net, even when restricted to
_symmetricnet.pntd_, is very expressive. Even the base _pnmlcore.pntd_ is useful.

## Why no Schema Verification

Within PNML.jl no schema-level validation is done.

Note that, depending on context, 'PNML' may refer to either
the markup language or the Julia code in the following.

In is allowed by the PNML specification to omit validation with the presumption that
some specialized, external tool can be applied, thus allowing the file format to be
used for inter-tool communication with lower overhead in each tool.

Also omiting pntd validation allows "duck typing" of Petri Nets built upon the
PNML intermediate representration.

Of some note it that PNML.jl extends PNML. These, non-standard pntd do not
(yet) have a schema written. See [`ContinuousNet`](@ref).

## PNTD Maps

Defaut PNTD to Symbol map (URI string to pntd symbol):
```@example
using PNML; foreach(println, sort(collect(pairs(PNML.PnmlTypeDefs.default_pntd_map)))) #hide
```

PnmlType map (pntd symbol to singleton):
```@example
using PNML; foreach(println, pairs(PNML.PnmlTypeDefs.pnmltype_map)) #hide
```

## Handling Labels

The implementation of Labels supports _annotation_ and _attribute_ format labels.

### Annotation Labels

_annotation_ format labels are expected to have either a <text> element,
a <structure> element or both. Often the <text> is a human-readable representation
of of the <structure> element. `Graphics` and `ToolInfo` elements may be present.

For `PTNet` (and `pnmlcore`) only the `Name` label with a <text> element
(and no <structure> element) is defined by the specification.

Labels defined in High-Level pntds, specifically 'Symmetric Nets',
"require" all meaning to reside in the <structure>.

### Attribute Labels

_attribute_ format labels are present in the UML model of pnml.
They differ from _annotation_ by omitting the `Graphics` element,
but retain the `ToolInfo` element. Unless an optimization is identified,
both _attribute_ and _annotation_ will share the same implementation.

A standard-conforming pnml model would not have any `Graphics` element
so that field would be `nothing`.


## High-level Petri Net Concepts

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


### Terms

Terms have *sort*s: the sort of the variable or the output sort of the operator.

Terms can be buit from built-in *operator*s and *sort*s, and user-defined *variable*s.
These are defined in *variable declaration*s, a kind of *annotation* label attached to *page*s and *net*s.

A *transition* can have a *condition*, a term of *sort* boolean,
which imposes restrictions on when the transition may fire.

### Sorts

*named sort*s are constructed from existing *sort*s and given a new name.

*arbitrary sort* is not defined in core, is not allowed in *Symmetric Nets*.
HLPNG adds *arbitrary declarations*, sorts of *lists*, *strings*, *integers* to *Symmetric Nets*.

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

## Notes on Petri Nets

### Multiset Rewriting Systems

I. Cervesato: [Petri Nets as Multiset Rewriting Systems in a Linear Framework](https://citeseerx.ist.psu.edu/document?repid=rep1&type=pdf&doi=d5e629e53d831d63d04ac1520e7f7774273488b8)

This addresses Place Transition Nets. High-level Petri nets explictily use multisets.

> factor out the multiplicity of the elements of the underlying set. This is achieved by first defining the notion of singleton multisets and then by writing arbitrary multisets as linear combination of singleton multisets.

> a rewrite rule can be viewed as a singleton multiset

> Petri nets are meant to represent evolving systems. To represent this dynamic flavor, we will rely on the notion of multiset rewriting systems.

## Continuous, Open and Other Petri Nets

Allow marking, inscription, conditions to be floating point even when specification
wants an integer. This allows continuous nets.

See [Petri.jl](https://github.com/mehalter/Petri.jl)
and [AlgebraicPetri.jl](https://github.com/AlgebraicJulia/AlgebraicPetri.jl)
for some continuous Petri Net use-cases.

TODO: Hybrid nets combining floating point/continuous and integer/discrete
inscription/marking.


## References

[www.pnml.org](https://www.pnml.org/)

L.M. Hillah and E. Kindler and F. Kordon and L. Petrucci and N. Trèves:
[*A primer on the Petri Net Markup Language and ISO/IEC 15909-2*](https://www.pnml.org/papers/pnnl76.pdf)
Petri Net Newsletter 76:9--28, October 2009 (originally presented at the 10th International workshop on Practical Use of Colored Petri Nets and the CPN Tools -- CPN'09).

ISO *High-level Petri nets* Specification in multiple parts:
- [*ISO/IEC 15909-1:2019 — Part 1: Concepts, definitions and graphical notation*](https://www.iso.org/en/contents/data/standard/06/72/67235.html)
- [*ISO/IEC 15909-2:2011 — Part 2: Transfer format*](https://www.iso.org/en/contents/data/standard/04/35/43538.html)
- [*ISO/IEC 15909-2:2011/Cor 1:2013 — Part 2: Transfer format — TECHNICAL CORRIGENDUM 1*](https://www.iso.org/en/contents/data/standard/06/28/62800.html)
- [*ISO/IEC 15909-3:2021 — Part 3: Extensions and structuring mechanisms*](https://www.iso.org/en/contents/data/standard/08/15/81504.html)

[_nLab_](https://ncatlab.org/nlab/) a wiki for collaborative work on Mathematics, Physics, and Philosophy:
   - [multisorted algebraic theories](https://ncatlab.org/nlab/show/algebraic+theory#multisorted_algebraic_theories)
   - [Petri net](https://ncatlab.org/nlab/show/Petri+net)


[Well-formed Petri nets](https://en.wikipedia.org/wiki/Well-formed_Petri_net)
"...only a limited set of operators are available (identify, broadcast, successor and predecessor functions are allowed on circular finite types)".
Restrictions that differentiates `SymmetricNet` and `HLPNG`.

John Baez, Fabrizio Genovese, Jade Master, Michael Shulman, _Categories of Nets_, [arXiv:2101.04238](https://arxiv.org/abs/2101.04238)

R.J. van Glabbeek (2005): [_The Individual and Collective Token Interpretations of Petri Nets_](http://boole.stanford.edu/pub/individual.pdf).
In M. Abadi & L. de Alfaro, editors:
_Proceedings 16th International Conference on Concurrency Theory, CONCUR’05_,
San Francisco, USA, LNCS 3653, Springer, pp. 323-337.

[PNML Framework](https://pnml.lip6.fr/)
"... a free and open-source prototype implementation of ISO/IEC-15909, International Standard on Petri Nets".
The framework is an Eclipse/Java construction using Eclipse Public License 1.0.
Uses Model-Driven Engineering to provide generated APIs.

[github.com/lip6/pnmlframework](https://github.com/lip6/pnmlframework) hosts the source code of PNML Framework.
See [apidocs](https://pnml.lip6.fr/pnmlframework/apidocs/index.html) and
[XMLTestFilesRepository](https://github.com/lip6/pnmlframework/tree/master/pnmlFw-Tests/XMLTestFilesRepository).


[github.com/loig/pinimili](https://github.com/loig/pinimili)
Go language.

[github.com/stackdump/gopetri](https://github.com/stackdump/gopetri)
Go language.

[github.com/daemontus/pnml-parser](https://github.com/daemontus/pnml-parser)
Rust language.

 [Browsable PNML Grammar from Grammar Zoo](https://slebok.github.io/zoo/automata/petri/pnml/standard/symmetric/extracted/index.html)
 For Symmetric Nets.

[Automated Code Optimization with E-Graphs](https://arxiv.org/abs/2112.14714): Alessandro Cheli's Thesis on Metatheory.jl.

[ePNK](http://www.imm.dtu.dk/~ekki/projects/ePNK/index.shtml) a platform for developing Petri net tools based on the PNML transfer format is another Eclipse/Java EMF thing. Implements more complicated PNML than used in MCC. By authors of PNML.
[github](https://github.com/ekkart/ePNK) has the source, documentation, examples.

"The [Model Checking Contest (MCC)](https://mcc.lip6.fr/) has two different parts:
the Call for Models, which gathers Petri net models proposed by the scientific community,
and the Call for Tools, which benchmarks verification tools developed within the scientific community."
Each year new models are added to the contest.

 "[Petri net model using AlgebraicPetri.jl](https://github.com/epirecipes/sir-julia/blob/master/markdown/pn_algebraicpetri/pn_algebraicpetri.md#petri-net-model-using-algebraicpetrijl) Micah Halter, 2021-03-26"
