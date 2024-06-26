```@meta
CurrentModule = PNML
```

## Evaluate possible functors

Things that are functors:
  - Marking: return [`marking_value_type`](@ref)
  - Inscription: return [`inscription_value_type`](@ref)
  - Condition: return [`condition_value_type`](@ref)
  - Term: return a sort's value type **TBD**

```@setup methods
using AbstractTrees, PNML, InteractiveUtils, Markdown
```

[`_evaluate`](@ref)
```@example methods
methods(PNML._evaluate) # hide
```

## Examples

```jldoctest; setup=(using PNML: _evaluate)
julia> _evaluate(1)
1

julia> _evaluate(true)
true
```
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

```
value(mark) = Term(:add,
    (d["subterm"] = [(d["numberof"] = (d["subterm"] =
                            [(d["numberconstant"] = (d[:value] = "1", d["positive"] = ())),
                             (d["numberconstant"] = (d[:value] = "3", d["positive"] = ()))])),
                     (d["numberof"] = (d["subterm"] =
                            [(d["numberconstant"] = (d[:value] = "1", d["positive"] = ())),
                             (d["numberconstant"] = (d[:value] = "2", d["positive"] = ()))]))]))

```

Constructs an expression that adds 2 multisets.
When all multiplicities are 1 and sortof subterm has an eltype (is simple), can apply usual math operator.
Output sort needs to match eltype of operation result in case there is promotion.

```
1`3 + 1`2 = 3 + 2 = 5
2`3 + 1`2 = 3 + 3 + 2 = 8
```
# Zero
```julia
value(mark) = Term(:zero, 0)
```
