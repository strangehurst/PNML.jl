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

See [Extending PNML Scope: a Framework to Combine Petri Nets Types](https://www.pnml.org/papers/topnoc-2012.pdf) for concepts relevant to *ISO/IEC 15909-3*.

Note that the pnml XML file is the working intermediate representation of a suite of tools that use
RelaxNG and Schematron for validation of the interchange file's content.

## Interoperability

Petri Net Type Definition schema files (pntd) are defined using RELAX-NG XML Schema files (rng).
Petri Net Markup Language files (pnml) are intended to be validated against a pntd schema.

For interchange of pnml between tools it should be enough to support the same pntd schema.

Note that ISO released part 3 of the PNML standard covering extensions and structuring mechanisms in 2021. And some http://www.pnml.org files address these extensions.
Including [Extending PNML Scope: a Framework to Combine Petri Nets Types](https://www.pnml.org/papers/topnoc-2012.pdf).


It is possible to create a non-standard pntd. And more will be standardized, either
formally or informally. Non-standard mostly means that the interchangibility is restricted.

Since validation is not a goal of PNML.jl the uri is treated as a string.
So non-standard pntds can be used for the URI of an XML `net` tag's `type` attribute.
Notably `pnmlcore` and `nonstandard` are mapped to [`PnmlCoreNet`](@ref).

`PnmlCoreNet` is the minimum level of meaning that any pnml file can hold.

Further parsing of labels is specialized upon subtypes of [`PNML.AbstractPetriNet`](@ref).
See [Traits](@ref) for more details.

If you want interchangability of pnml models, you will have to stick to
the standard pnml pntds. The High Level Petri Net, even when restricted to
_symmetricnet.pntd_, is very expressive. Even the base _pnmlcore.pntd_ is useful.

## Why no Schema Verification

Within PNML.jl no schema-level validation is done.

Note that, depending on context, 'PNML' may refer to either
the markup language or the Julia code in the following.

In is allowed by the PNML standard to omit validation with the presumption that
some specialized, external tool can be applied, thus allowing the file format to be
used for inter-tool communication with lower overhead in each tool.

Also omiting pntd validation allows "duck typing" of Petri Nets built upon the
PNML intermediate representration.

Of some note it that PNML.jl extends PNML. These, non-standard pntd do not
(yet) have a schema written. See [`ContinuousNet`](@ref).

## References

[www.pnml.org](https://www.pnml.org/)

L.M. Hillah and E. Kindler and F. Kordon and L. Petrucci and N. Trèves:
[*A primer on the Petri Net Markup Language and ISO/IEC 15909-2*](https://www.pnml.org/papers/pnnl76.pdf)
Petri Net Newsletter 76:9--28, October 2009 (originally presented at the 10th International workshop on Practical Use of Colored Petri Nets and the CPN Tools -- CPN'09).

ISO *High-level Petri nets* Standard in multiple parts:
- [*ISO/IEC 15909-1:2019 — Part 1: Concepts, definitions and graphical notation*](https://www.iso.org/en/contents/data/standard/06/72/67235.html)
- [*ISO/IEC 15909-2:2011 — Part 2: Transfer format*](https://www.iso.org/en/contents/data/standard/04/35/43538.html)
- [*ISO/IEC 15909-2:2011/Cor 1:2013 — Part 2: Transfer format — TECHNICAL CORRIGENDUM 1*](https://www.iso.org/en/contents/data/standard/06/28/62800.html)
- [*ISO/IEC 15909-3:2021 — Part 3: Extensions and structuring mechanisms*](https://www.iso.org/en/contents/data/standard/08/15/81504.html)

[Towards a Standard for Modular Petri Nets:A Formalisation](https://portail.lipn.univ-paris13.fr/portail/plugins/publications/fichiers/EK-LP-ATPN09.pdf) expounds on structuring mechanism in 15909-3.
From Proc. 30th Int. Conf. Application and Theory of Petri Nets (PetriNets’2009), Paris, France, June 2009, volume 5606 of Lecture Notes in Computer Science. Springer, 2009.

[Extending PNML Scope: a Framework to Combine Petri Nets Types](https://www.pnml.org/papers/topnoc-2012.pdf)
L.M. Hillah and F. Kordon and C. Lakos and L. Petrucci, Transactions on Petri Nets and Other Models of Concurrency, Springer 2012, LNCS 7400 (VI), pp.46-70

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
Uses 'Eclipse` Model-Driven Engineering [EMF](http://www.eclipse.org/modeling/emf/) to provide generated APIs.

[github.com/lip6/pnmlframework](https://github.com/lip6/pnmlframework) hosts the source code of PNML Framework.
See [apidocs](https://pnml.lip6.fr/pnmlframework/apidocs/index.html) and
[XMLTestFilesRepository](https://github.com/lip6/pnmlframework/tree/master/pnmlFw-Tests/XMLTestFilesRepository).

[github.com/loig/pinimili](https://github.com/loig/pinimili)
Go language.

[github.com/stackdump/gopetri](https://github.com/stackdump/gopetri)
Go language.

[Petri net visualisator written in Go.](https://github.com/drahoslove/penego)
Go language. Non-standard pnml xml syntax.

[LTSmin](https://github.com/utwente-fmt/ltsmin) "a full (LTL/CTL/μ-calculus) model checker".
C/M4/C++ language.

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

[Nested-Unit Petri Nets (NUPN)](https://mcc.lip6.fr/2025/nupn.php)
an "extension of P/T nets" used by MCC:
  - existence of units has no effect on the transition firing rules
  - partitions the set of places
  - if a net is unit-safe, units express linear inequality invariants on reachable markings, and tools may take advantage of such invariants to perform logarithmic reductions in the size of marking encodings.


 "[Petri net model using AlgebraicPetri.jl](https://github.com/epirecipes/sir-julia/blob/master/markdown/pn_algebraicpetri/pn_algebraicpetri.md#petri-net-model-using-algebraicpetrijl) Micah Halter, 2021-03-26"
