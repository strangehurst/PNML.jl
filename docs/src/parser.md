```@meta
CurrentModule = PNML
```

# Parser

## Type Map

```@example
using PNML; using PNML: tagmap
for t in keys(tagmap)
    println(t)
end
```

## Unclaimed Labels

XML tags that are not 'claimed' are recursively parsed into a [`AnyXmlNode`](@ref)
tree whose leaf nodes are strings by [`unclaimed_label`](@ref).

See [`AnyElement`](@ref), [`anyelement`](@ref), [`PnmlLabel`](@ref), [`Term`](@ref).

## AnyElement

Main use case if for [`ToolInfo`](@ref) content.
The specification allows any well-formed XML.
Only the intended tool needs to understand the content.

__TODO__ Implement a `ToolInfo` for PNML.jl extensions.

## PnmlLabel

Applies label semantics to a vector of `AnyXmlNode`s.
Used for not-yet-implemented labels. Many of the labels used for high-level many-sorted algebra have not been implemented.

See [`rate`](@ref) for a use case.
