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
default_condition(p::PnmlType) = Condition(p, true)
default_inscription(::PnmlType) = one(Int)
default_marking(::PnmlType) = Marking(zero(Int))

#------------------------------------------------------------------------------
default_condition(p::AbstractContinuousNet) = Condition(p, true)
default_inscription(::AbstractContinuousNet) = one(Float64)
default_marking(::AbstractContinuousNet) = Marking(zero(Float64))
