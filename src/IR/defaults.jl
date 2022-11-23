"""
$(TYPEDSIGNATURES)
Return default condition based on `PNTD`. Has meaning of true or always.
```
"""
function default_condition end
default_condition(::PnmlType) = Condition(true)

"""
$(TYPEDSIGNATURES)
Return default inscription value based on `PNTD`. Has meaning of unity, as in `one`.
"""
function default_inscription end
default_inscription(::PnmlType) = one(Int)

"""
$(TYPEDSIGNATURES)
Return default marking value based on `PNTD`. Has meaning of empty, as in `zero`.
"""
function default_marking end
default_marking(::PnmlType) = PTMarking(zero(Int))

#------------------------------------------------------------------------------
default_condition(::AbstractContinuousNet) = Condition(true)
default_condition(::AbstractHLCore) = Condition(true) #! should be a term

#------------------------------------------------------------------------------
default_marking(::AbstractContinuousNet) = PTMarking(zero(Float64))
default_marking(pntd::AbstractHLCore) = HLMarking(default_zero_term(pntd))


#------------------------------------------------------------------------------
default_inscription(::AbstractContinuousNet) = one(Float64)
default_inscription(pntd::AbstractHLCore) = default_one_term(pntd)
