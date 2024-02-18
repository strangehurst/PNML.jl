```@meta
CurrentModule = PNML
```

# Default Values

  - markings: return zero(`Int`), zero(`Float64`), or `default_zero_term(pntd)`
  - inscription: return one(`Int`), one(`Float64`), or `default_one_term(pntd)`
  - condition: return `true`, or `default_condition(pntd)`
  - Term: return boolean sort's true value `default_bool_term(pntd)`

The _ISO/IEC 15909-2_ specification and the RelaxNG Schemas state 'natural numbers' and 'non-zero natural numbers'. I choose to also allow continuous values to support nonstandard continuous and hybrid valued Petri Nets. Makes generating default values more interesting.

Determine type of `Number` to parse with [`number_value`](@ref) by using `pntd` on:
  - [`condition_value_type`](@ref)
  - [`inscription_value_type`](@ref)
  - [`marking_value_type`](@ref)
  - [`coordinate_value_type`](@ref)
  - [`term_value_type`](@ref)
  - [`rate_value_type`](@ref)


There are many items in the XML that are permitted to be missing and a defaut value is assumed.
Examples are place _initial marking_, arc _inscription_, transition _condition_, graphics data.

  - place initial marking is assumed to be empty, i. e. 0.
  - arc inscription is assumed to be 1.
  - transition condition is assumed to be true
  - graphics data, e.g. token position, line width, are TBD


There are multiple kinds of nets supported by PNML.jl differing by (among other properties)
the kind on number they use:
  - discrete,
  - continuous,
  - and multi-sorted algebra
See [PnmlType - Petri Net Type Definition](@ref) for the full hierarchy.

This means there are at least 3 sets of default value types.
We use the pntd [`PnmlType`](@ref) singleton as a trait to determin the default types/values.

A consequence is that the default value's type ripples through the type system.

```@setup methods
using AbstractTrees, PNML, InteractiveUtils, Markdown
list_type(f) = for pntd in values(PNML.PnmlTypeDefs.pnmltype_map)
    println(rpad(pntd, 15), " -> ", f(pntd))
end
```

## Methods

[`PNML.default_marking`](@ref)

```@example methods
list_type(PNML.default_marking)
```
```@example methods
methods(PNML.default_marking) # hide
```

[`PNML.default_inscription`](@ref)

```@example methods
list_type(PNML.default_inscription) # hide
```
```@example methods
methods(PNML.default_inscription) # hide
```

[`PNML.default_condition`](@ref)

```@example methods
list_type(PNML.default_condition) # hide
```
```@example methods
methods(PNML.default_condition) # hide
```

[`PNML.default_sort`](@ref)

```@example methods
list_type(PNML.default_sort) # hide
```
```@example methods
methods(PNML.default_sort) # hide
```

[`PNML.default_one_term`](@ref)

```@example methods
list_type(PNML.default_one_term) # hide
```
```@example methods
methods(PNML.default_one_term) # hide
```

[`PNML.default_zero_term`](@ref)

```@example methods
list_type(PNML.default_zero_term) # hide
```
```@example methods
methods(PNML.default_zero_term) # hide
```

[`PNML.default_bool_term`](@ref)

```@example methods
list_type(PNML.default_bool_term) # hide
```
```@example methods
methods(PNML.default_bool_term) # hide
```

## Examples

[`PNML.default_one_term`](@ref), [`PNML.default_zero_term`](@ref)

```jldoctest; setup=:(using PNML; using PNML: default_condition)
julia> c = default_condition(PnmlCoreNet())
Condition("", Term(:bool, true))

julia> c()
true

julia> c = default_condition(ContinuousNet())
Condition("", Term(:bool, true))

julia> c = default_condition(HLCoreNet())
Condition("", Term(:bool, true))
```


```jldoctest; setup=:(using PNML; using PNML: default_inscription)
julia> i = default_inscription(PnmlCoreNet())
Inscription(1)

julia> i = default_inscription(ContinuousNet())
Inscription(1.0)

julia> i = default_inscription(HLCoreNet())
HLInscription("", Term(:one, 1))

julia> i()
1
```


```jldoctest; setup=:(using PNML; using PNML: default_marking, Marking, HLMarking, pnmltype)
julia> m = default_marking(PnmlCoreNet())
Marking(0)

julia> m()
0

julia> m = default_marking(ContinuousNet())
Marking(0.0)

julia> m()
0.0

julia> m = default_marking(HLCoreNet())
HLMarking("", Term(:zero, 0))

julia> m()
0
```
