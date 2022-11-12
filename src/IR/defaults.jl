"""
$(TYPEDSIGNATURES)
Return default condition based on `PNTD`. Has meaning of true or always.
```
"""
function default_condition end
default_condition(::PNTD) where {PNTD <: PnmlType} = Condition(true)
default_condition(::Type{PNTD}) where {PNTD <: PnmlType} = Condition(true)

"""
$(TYPEDSIGNATURES)
Return default inscription value based on `PNTD`. Has meaning of unity, as in `one`.
"""
function default_inscription end
default_inscription(::PNTD) where {PNTD <: PnmlType} = one(Int)

"""
$(TYPEDSIGNATURES)
Return default marking value based on `PNTD`. Has meaning of empty, as in `zero`.
"""
function default_marking end
default_marking(::PNTD) where {PNTD <: PnmlType} = PTMarking(zero(Int))
default_marking(::Type{PNTD}) where {PNTD <: PnmlType} = PTMarking(zero(Int))

#------------------------------------------------------------------------------
default_condition(::PNTD) where {PNTD <: AbstractContinuousNet} = Condition(true)
default_condition(::Type{PNTD}) where {PNTD <: AbstractContinuousNet} = Condition(true)
default_condition(pntd::PNTD) where {PNTD <: AbstractHLCore} = Condition(true) #! should be a term
default_condition(::Type{PNTD}) where {PNTD <: AbstractHLCore} = Condition(true)

#------------------------------------------------------------------------------
default_marking(::PNTD) where {PNTD <: AbstractContinuousNet} = PTMarking(zero(Float64))
default_marking(::Type{PNTD}) where {PNTD <: AbstractContinuousNet} = PTMarking(zero(Float64))
default_marking(pntd::PNTD) where {PNTD <: AbstractHLCore} = HLMarking(default_zero_term(pntd))


#------------------------------------------------------------------------------
default_inscription(::PNTD) where {PNTD <: AbstractContinuousNet} = one(Float64)
default_inscription(pntd::PNTD) where {PNTD <: AbstractHLCore} = default_one_term(pntd)
