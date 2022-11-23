"""
$(TYPEDSIGNATURES)
Return default condition based on `PNTD`. Has meaning of true or always.
```
"""
function default_condition end
default_condition(x::Any) = error("no default condition for $(typeof(x))")

"""
$(TYPEDSIGNATURES)
Return default inscription value based on `PNTD`. Has meaning of unity, as in `one`.
"""
function default_inscription end
default_inscription(x::Any) = error("no default inscription for $(typeof(x))")

"""
$(TYPEDSIGNATURES)
Return default marking value based on `PNTD`. Has meaning of empty, as in `zero`.
"""
function default_marking end
default_marking(x::Any) = error("no default marking for $(typeof(x))")

#------------------------------------------------------------------------------
default_condition(::PnmlType) = Condition(true)
default_inscription(::PnmlType) = one(Int)
default_marking(::PnmlType) = PTMarking(zero(Int))

#------------------------------------------------------------------------------
default_condition(::AbstractContinuousNet) = Condition(true)
default_inscription(::AbstractContinuousNet) = one(Float64)
default_marking(::AbstractContinuousNet) = PTMarking(zero(Float64))

#------------------------------------------------------------------------------
default_condition(::AbstractHLCore) = Condition(true) #! should be a term
default_inscription(pntd::AbstractHLCore) = default_one_term(pntd)
default_marking(pntd::AbstractHLCore) = HLMarking(default_zero_term(pntd))
