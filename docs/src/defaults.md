```@meta
CurrentModule = PNML
```

# Default Values
Varies by PNTD. Possibilitie include:
  - markings: return zero(`Int`), zero(`Float64`), or empty multiset of same sort as adjacent place's sorttype.
  - inscription: return one(`Int`), one(`Float64`), or singleton multiset of same sort as adjacent place's sorttype with value of first(elements(sort)).
  - condition: return `true`, or `BooleanConstant(true)`

The _ISO/IEC 15909-2_ specification and the RelaxNG Schemas state 'natural numbers' and 'non-zero natural numbers'. I choose to also allow continuous values to support nonstandard continuous and hybrid valued Petri Nets. Makes generating default values more interesting.

Determine type of `Number` to parse with [`number_value`](@ref) by using `pntd` on:
  - [`condition_value_type`](@ref)
  - [`inscription_value_type`](@ref)
  - [`marking_value_type`](@ref)
  - [`coordinate_value_type`](@ref)
  - removed term_value_type
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
We use the pntd [`PnmlType`](@ref) as a trait to determine the default types/values.

A consequence is that the default value's type ripples through the type system.

```@setup methods
using AbstractTrees, PNML, InteractiveUtils, Markdown
using PNML: default_condition
using PNML: default_inscription, default_hlinscription
using PNML: default_marking, default_hlmarking
using PNML: SortType, UserSort, IntegerSort, DotSort,
            PnmlCoreNet, ContinuousNet, HLCoreNet,
            NumberConstant, DotConstant

list_type(f) = for pntd in values(PNML.PnmlTypeDefs.pnmltype_map)
    println(rpad(pntd, 15), " -> ", f(pntd))
end
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

## Examples
```@meta
DocTestSetup = quote
    using Base.ScopedValues
    using PNML
    using PNML: default_condition
    using PNML: default_inscription, default_hlinscription
    using PNML: default_marking, default_hlmarking
    using PNML: SortType, UserSort, IntegerSort, DotSort,
                PnmlCoreNet, ContinuousNet, HLCoreNet,
                NumberConstant, DotConstant
 end
```

```jldoctest
julia> c = @with PNML.DECLDICT => PNML.DeclDict() default_condition(PnmlCoreNet())
Condition("", BooleanEx(PNML.BooleanConstant(true)))

julia> c()
true

julia> c = @with PNML.DECLDICT => PNML.DeclDict() default_condition(ContinuousNet())
Condition("", BooleanEx(PNML.BooleanConstant(true)))

julia> c = @with PNML.DECLDICT => PNML.DeclDict() default_condition(HLCoreNet())
Condition("", BooleanEx(PNML.BooleanConstant(true)))
```
