"""
$(TYPEDSIGNATURES)

Return default condition based on `PNTD`. Has meaning of true or always.

# Examples

```jldoctest; setup=:(using PNML; using PNML: default_condition)
julia> m = default_condition(PnmlCore())
Condition(nothing, true, )

julia> m = default_condition(ContinuousNet())
Condition(nothing, true, )

julia> m = default_condition(HLCore())
Condition(nothing, true, )
```
"""
function default_condition end
default_condition(::PNTD) where {PNTD <: PnmlType} = Condition(true)
default_condition(::Type{PNTD}) where {PNTD <: PnmlType} = Condition(true)

default_condition(::PNTD) where {PNTD <: AbstractContinuousNet} = Condition(true)
default_condition(::Type{PNTD}) where {PNTD <: AbstractContinuousNet} = Condition(true)

default_condition(pntd::PNTD) where {PNTD <: AbstractHLCore} = Condition(true) #! should be a term
default_condition(::Type{PNTD}) where {PNTD <: AbstractHLCore} = Condition(true)

"""
$(TYPEDSIGNATURES)

Return default inscription value based on `PNTD`. Has meaning of unity, as in `one`.

# Examples

```jldoctest; setup=:(using PNML; using PNML: default_inscription)
julia> i = default_inscription(PnmlCore())
1

julia> i = default_inscription(ContinuousNet())
1.0

julia> i = default_inscription(HLCore())
Term(:empty, Dict(:value => 1))

julia> i()
1

```
"""
function default_inscription end
default_inscription(::PNTD) where {PNTD <: PnmlType} = one(Int)
default_inscription(::PNTD) where {PNTD <: AbstractContinuousNet} = one(Float64)
default_inscription(pntd::PNTD) where {PNTD <: AbstractHLCore} = default_one_term(pntd)

"""
$(TYPEDSIGNATURES)

Return default marking value based on `PNTD`. Has meaning of empty, as in `zero`.

# Examples

```jldoctest; setup=:(using PNML; using PNML: default_marking, PTMarking, HLMarking, pnmltype)
julia> m = default_marking(pnmltype(PnmlCore()))
PTMarking(0, )

julia> m()
0

julia> m = default_marking(typeof(pnmltype(PnmlCore())))
PTMarking(0, )

julia> m()
0

julia> m = default_marking(pnmltype(HLCore()))
HLMarking(nothing, Term(:empty, Dict(:value => 0)), )

julia> m()
0
```
"""
function default_marking end
default_marking(::PNTD) where {PNTD <: PnmlType} = PTMarking(zero(Int))
default_marking(::Type{PNTD}) where {PNTD <: PnmlType} = PTMarking(zero(Int))

default_marking(::PNTD) where {PNTD <: AbstractContinuousNet} = PTMarking(zero(Float64))
default_marking(::Type{PNTD}) where {PNTD <: AbstractContinuousNet} = PTMarking(zero(Float64))

default_marking(pntd::PNTD) where {PNTD <: AbstractHLCore} = HLMarking(default_zero_term(pntd))

