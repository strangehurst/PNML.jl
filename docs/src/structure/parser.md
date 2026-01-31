```@meta
CurrentModule = PNML
```

# Parser

## Initial Markings

Parsed into [`PnmlExpr`](@ref) expressions in a `Place`.
Place/Transition Petri net and Continuous net markings are treated as `<numberconstant>`.
Allows same machanism to be used for all flavors of nets after parsing.

Marking is a ground term and is used to give a Petri net marking vector an initial value.



## Unclaimed Labels

XML tags that are not 'claimed' are recursively parsed into a [`XmlDictType`](@ref) by [`Parser.xmldict`](@ref).

See [`AnyElement`](@ref), [`Parser.anyelement`](@ref), [`PnmlLabel`](@ref)

## AnyElement

Main use case if for [`ToolInfo`](@ref) content.
The standard allows any well-formed XML.
Only the intended tool needs to understand the content.

__TODO__ Implement a `ToolInfo` for PNML.jl extensions.

## PnmlLabel

Applies label semantics to a `XmlDictType`.
Used for not-yet-implemented labels. Many of the labels used for high-level many-sorted algebra have not been implemented.

See [`rate_value`](@ref) for a use case.


## Structure of High-level Annotation

Schematic of annotation label:
- text
- structure
  * Term
    - subterm
      * Term (its alternating subterm Term all the way down)
- toolspecific
- graphics
