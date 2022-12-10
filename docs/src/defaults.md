# Default Values

ISO/IEC 15909-2 defines the _Petri Net Modeling Language (PNML)_ as integer based.
There are many items in the XML that are permitted to be missing and a defaut value is assumed.
Examples are place _initial marking_, arc _inscription_, transition _condition_, graphics data.

  - place initial marking is assumed to be empty, i. e. 0.
  - arc inscription is assumed to be 1.
  - transition condition is assumed to be true
  - graphics data, e.g. token position, line width, are chosen by application

The specification and the RelaxNG Schemas state 'natural numbers' and 'non-zero natural numbers'. I choose to allow continuous values. Parsing the string for a value is first tried as 'Int' and then 'Float64'.  But it allows for nonstandard continuous and hybrid valued Petri Nets.

See [PnmlType - Petri Net Type Definition](@ref). There are 3 kinds of nets supported by PNML.jl: discrete, continuous/hybrid, and high-level (discrete).

High-level nets are not completely implemented (as of November 2022). Also supporting continuous/hybrid high-level nets may not be possible.

The values used for markings, inscriptions, conditions arepart of a multi-sorted algebra.

  - default\_sort, where sort is for the many-sorted algebra defined for high-level nets.
  - default\_one\_term
  - default\_zero\_term


```jldoctest; setup=:(using PNML; using PNML: default_condition)
julia> m = default_condition(PnmlCore())
Condition(nothing, true, )

julia> m = default_condition(ContinuousNet())
Condition(nothing, true, )

julia> m = default_condition(HLCore())
Condition(nothing, true, )
```


```jldoctest; setup=:(using PNML; using PNML: PnmlDict, default_inscription)
julia> i = default_inscription(PnmlCore())
1

julia> i = default_inscription(ContinuousNet())
1.0

julia> i = default_inscription(HLCore())
Term(:empty, IdDict{Symbol, Any}(:value => 1))

julia> PnmlDict
IdDict{Symbol, Any}

julia> i()
1
```


```jldoctest; setup=:(using PNML; using PNML: default_marking, PTMarking, HLMarking, pnmltype)
julia> m = default_marking(PnmlCore())
PTMarking(0, )

julia> m()
0

julia> m = default_marking(ContinuousNet())
PTMarking(0.0, )

julia> m()
0.0

julia> m = default_marking(HLCore())
HLMarking(nothing, Term(:empty, IdDict{Symbol, Any}(:value => 0)), )

julia> PnmlDict
IdDict{Symbol, Any}

julia> m()
0
```
