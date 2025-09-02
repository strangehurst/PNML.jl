```@meta
CurrentModule = PNML
```

## Evaluate possible functors

Things that are functors:
  - Marking:
  - Inscription
  - Condition
  - Term: return a sort's value type **TBD**

```@setup methods
using PNML, InteractiveUtils, Markdown
```

## Examples

## XMLDict format Terms
[XMLDict.jl](https://github.com/JuliaCloud/XMLDict.jl)

> XMLDict implements an Associative interface (get(), getindex(), haskey())
> for reading XML elements and attributes.

### Operator that constructs a multiset of sort dot.

A marking is a multiset of a place's sorttype. The output sort of the operator must be of this sort (equatSorts is true and sortof(place) == sortof(marking)).

The output sort of numberof is the sort of the element in 2nd subterm.

`positive` and `dotconstant` are `builtin-constants`.

### Tuple


# Add multisets

```xml
<hlinitialMarking>
    <text>1`3 ++ 1`2</text>
    <structure>
        <add>
            <subterm>
                <numberof>
                <subterm><numberconstant value=\"1\"><positive/></numberconstant></subterm>
                <subterm><numberconstant value=\"3\"><positive/></numberconstant></subterm>
                </numberof>
            </subterm>
            <subterm>
                <numberof>
                <subterm><numberconstant value=\"1\"><positive/></numberconstant></subterm>
                <subterm><numberconstant value=\"2\"><positive/></numberconstant></subterm>
                </numberof>
            </subterm>
        </add>
    </structure>
</hlinitialMarking>
```

Constructs an expression that adds 2 multisets.
When all multiplicities are 1 and sortof subterm has an eltype the usual math applies.
Output sort needs to match eltype of operation result.

```
1`3 + 1`2 = 3 + 2 = 5
2`3 + 1`2 = 3 + 3 + 2 = 8
```
# Zero
