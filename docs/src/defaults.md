# Default Values

ISO/IEC 15909-2 defines the _Petri Net Modeling Language (PNML)_ as integer based.
There are many items in the XML that are permitted to be missing and a defaut value is assumed.
Examples are place _initial marking_, arc _inscription_, transition _condition_, graphics data.

  - place initial marking is assumed to be empty, i. e. 0.
  - arc inscription is assumed to be 1.
  - transition condition is assumed to be true
  - graphics data, e.g. token position, line width, are chosen by application

The specification and the RelaxNG Schemas state 'natural numbers' and 'non-zero natural numbers'.
I choose to also allow continuous values by trying to parse the XML string first as 'Int',
and then as 'Float64'.  Allows for nonstandard continuous and hybrid valued Petri Nets.
Makes generating default values more interesting.

There are multiple kinds of nets supported by PNML.jl differing by (among other properties)
the kind on number they use:
  - discrete,
  - continuous,
  - and multi-sorted algebra
See [PnmlType - Petri Net Type Definition](@ref) for the full hierarchy.

This means there are at least 3 sets of default value types. We use the pntd

A consequence is that the default value's type ripples through the type system.


```@setup methods
using AbstractTrees, PNML, InteractiveUtils, Markdown
```

## Methods

[`PNML.default_marking`](@ref)
```@example methods
methods(PNML.default_marking) # hide
```

[`PNML.default_inscription`](@ref)
```@example methods
methods(PNML.default_inscription) # hide
```

[`PNML.default_condition`](@ref)
```@example methods
methods(PNML.default_condition) # hide
```

[`PNML.default_sort`](@ref)
```@example methods
methods(PNML.default_sort) # hide
```

[`PNML.default_term`](@ref)
```@example methods
methods(PNML.default_term) # hide
```

[`PNML.default_one_term`](@ref)
```@example methods
methods(PNML.default_one_term) # hide
```

[`PNML.default_zero_term`](@ref)
```@example methods
methods(PNML.default_zero_term) # hide
```


## Examples

[`PNML.default_one_term`](@ref), [`PNML.default_zero_term`](@ref)

```jldoctest; setup=:(using PNML; using PNML: default_condition)
julia> c = default_condition(PnmlCoreNet())
Condition(nothing, true, )

julia> c()
true

julia> c = default_condition(ContinuousNet())
Condition(nothing, true, )

julia> c = default_condition(HLCoreNet())
Condition(nothing, Term(:empty, (value = true,)), )
```


```jldoctest; setup=:(using PNML; using PNML: default_inscription)
julia> i = default_inscription(PnmlCoreNet())
Inscription(1, )

julia> i = default_inscription(ContinuousNet())
Inscription(1.0, )

julia> i = default_inscription(HLCoreNet())
HLInscription("default", Term(:empty, (value = 1,)), )

julia> i()
1
```


```jldoctest; setup=:(using PNML; using PNML: default_marking, Marking, HLMarking, pnmltype)
julia> m = default_marking(PnmlCoreNet())
Marking(0, )

julia> m()
0

julia> m = default_marking(ContinuousNet())
Marking(0.0, )

julia> m()
0.0

julia> m = default_marking(HLCoreNet())
HLMarking(nothing, Term(:empty, (value = 0,)), )

julia> m()
0
```
