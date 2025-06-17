```@meta
CurrentModule = PNML
```

# Parser

## Unclaimed Labels

XML tags that are not 'claimed' are recursively parsed into a [`DictType`](@ref) by [`Parser.unparsed_tag`](@ref).

See [`AnyElement`](@ref), [`Parser.anyelement`](@ref), [`PnmlLabel`](@ref)

## AnyElement

Main use case if for [`ToolInfo`](@ref) content.
The specification allows any well-formed XML.
Only the intended tool needs to understand the content.

__TODO__ Implement a `ToolInfo` for PNML.jl extensions.

## PnmlLabel

Applies label semantics to a `DictType`.
Used for not-yet-implemented labels. Many of the labels used for high-level many-sorted algebra have not been implemented.

See [`rate_value`](@ref) for a use case.


## Sorts

Figure 11 of the _primer_ lists built-in sorts and functions for _Symmetric Nets_, a
restricted _High-Level Petri Net Graph_. See [`PnmlTypes`](@ref), [`PnmlTypes.HLPNG`](@ref)
and [`AbstractHLCore`](@ref)

Some of the restrictions:
- [`Declarations.ArbitrarySort`](@ref) and 'Unparsed' not allowed.
- carrier sets of all basic (is this built-in?) sorts are finite
- sorttype of a place must not be a multiset sort (but multiset is in the UML diagram)

What `HLPNG` adds:
- declarations for sorts and functions
- ArbitraryDeclarations: ArbitrarySort, ArbitraryOperator, Unparsed
- Integers
- Strings
- Lists

## Structure of High-level Annotation

Schematic of annotation label:
- text
- structure
  * Term
    - subterm
      * Term (its alternating subterm Term all the way down)
- toolspecific
- graphics

## Enabling and Firing

See discussions on PnmlTuple, ProductSorts and variables.

This is a discussion of ENABLING rule

`c::Condition` is attached to  `t::Transition`.

`preset(net, pid(t)) ∪ postset(net, pid(t))` are the attached arcs.

arc inscription expressions have variable arguments as do conditions.

vars are ordered collections in standard! It uses Abstract Math and UML2 to say so.
As they are the arguments to operators (expressions with variables), they need to be consistent.

0-ary operators are constants and literals (as ground terms without variables).
Rewriting may? optimize/minimize these terms.

There will be inscriptions in preset(t) that are ground terms (constant or literal).
Use in postset is the obvious case: generate token.
A preset ground term inscription will not have a variable and use a `multiplicity = 1`.
Value will be of the marking basis sort (like all inscriptions).
The inscription is enabled if `multiset[value] > 0`, and value is removed on firing.
This is the same behavior as for PTNets that use integer-valued markings and inscriptions.


## binding value set

Collection of subsitution dictionaries
created from binding value sets
of all incriptions by selecting one from each set.
`length(1st set) * length(2nd set) * ... length(nth set)`

Condition
    Each dictionary is one substitution for every variable
    Dict(REFID => value in binding_value_set(REFID))

    sub = Dict{REFID,Ref{SORT}}()

    Ref{SORT}(multiset element) || Ref{SORT}(multiset element, tuple index)
        REFID may be repeated
            multiple of same var in an inscrition <= multplicity of a value in marking multiset
        &/or
            same var in multiple inscriptions all with same value

    for each substituion tuple element
        sub(varid) maps the variable to a value
        Used in evaluating (c::Condition)() to filter the substituion collection

    for each preset(t) inscription
        bindings to marking values that satisfy the inscription.
        Only continue if all constraints are met, else return `false`.
        if var already has a binding only consider those values
            remove values from binding that do not satisfy this inscription
            value must be present in each marking of sufficent multiplicity
        #todo recursivly re-evaluate after each add?

 `PnmlTuple` that are `ProductSort` elements and julia `Tuple` are not the same.
^ The vars tuple may contain elements of a PnmlTuple. Use marking basis to decide.

 variables are how an element of marking multiset is identified/assessed.
 for each preset(t)
   - each element of each marking multiset is bound to the variable or variables  -> tuple of bindings
   - enabling rule returning true for a tuple of bindings adds tuple to enabled transition modes.

 Generate JIT compiled code that uses REFID to update the VariableDeclaration
 with arg reference information then applies/evaluates expression using the value.

? Each arg in iteratable ordered collection `args` is bound as the value of a
? pnml variable that appears within the expression tree rooted at `term`?

 Varible in tree is a REFID to a VariableDeclaration that has the name and sort.
 args are pairs of name (or REFID) and reference to marking value.

 Reference to marking value is only read here as part of enabling function.

 Make a copy of expression? Just during bring-up to verify same behavior & debug.
 Simplify the expression by rewriting once (not each use).
 The optimized expression still has variables at this point that are REFIDs.



 preset variables are a superset of postset variables.
 Every postset variable is also a preset variable.

 Variable v is bound to preset marking value (element of a multiset)
   - as tuple of place REFID index into marking_vector, and a mutiset element.
   - bv_sets is a vector of variable binding value sets, one for each variable
   - use multipicity(multiset, element) >= length(v in variables(inscription(arc)))
     to test enabled state of binding to an element
   - build a binding value set (bvs) of those element bindings that are enabled
   - each arc shares a bvs in bv_sets for each variable in variables(inscription(arc))
   - tr_vars records variables in transaction. There is a bv_sets for each REFID in tv_vars
   - one or more of the bvs members is selected for a firing
   -

 Use variable to remove element (decrease multiplicity) from preset, add element to postset.

 foreach preset(t) arc inscription vars tuple
   enabling rule iterates matches for variable sort in marking multiset
   testing each binding combination in condition functor.

 Will iterate over each preset(t) marking's multiset elements.
 There will be (must be) a variable for each sort in the multiset basis.
 PnmlTuples are unpacked into multiple variables.

 Variables that appear in more than one preset(t) marking basis
 must have the same value in each marking to be enabled
