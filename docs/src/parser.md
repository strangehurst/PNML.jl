```@meta
CurrentModule = PNML
```

# Parser

## Unclaimed Labels

XML tags that are not 'claimed' are recursively parsed into a [`DictType`](@ref) by [`unparsed_tag`](@ref).

See [`AnyElement`](@ref), [`anyelement`](@ref), [`PnmlLabel`](@ref), [`Term`](@ref).

## AnyElement

Main use case if for [`ToolInfo`](@ref) content.
The specification allows any well-formed XML.
Only the intended tool needs to understand the content.

__TODO__ Implement a `ToolInfo` for PNML.jl extensions.

## PnmlLabel

Applies label semantics to a `DictType`.
Used for not-yet-implemented labels. Many of the labels used for high-level many-sorted algebra have not been implemented.

See [`rate`](@ref) for a use case.


## Sorts

Figure 11 of the _primer_ lists built-in sorts and functions for _Symmetric Nets_, a
restricted _High-Level Petri Net Graph_. See [`SymmetricNet`](@ref), [`HLPNG`](@ref)
and [`AbstractHLCore`](@ref)

Some of the restrictions:
- [`ArbitrarySort`](@ref) and 'Unparsed' not allowed.
- carrier sets of all basic (is this built-in?) sorts are finite
- sorttype of a place must not be a multiset sort (but multiset is in the UML diagram)

What `HLPNG` adds:
- declarations for sorts and functions
- ArbitraryDeclarations: ArbitrarySort, ArbitraryOperator, Unparsed
- Integers
_ Strings
_ Lists

initialMarking
not
tuple
inscription
variable
pnml
equality
net
or
unparsed
useroperator
arc
usersort
referenceTransition
namedoperator
structure
mulitsetsort
booleanconstant
page
tokenposition
referencePlace
label
place
productsort
graphics
hlinscription
and
name
toolspecific
hlinitialMarking
bool
declaration
variabledecl
condition
inequality
transition
arbitraryoperator
arbitrarysort
sort
tokengraphics
text
type
imply

## Structure of High-level Annotation

Schematic of annotation label:
- text
- structure
  * Term
    - subterm
      * Term (its alternating subterm Term all the way down)
- toolspecific
- graphics
