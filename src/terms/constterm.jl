"""
    NumberConstant{T<:Number, S}

Builtin operator that has arity=0 means the same result every time, a constant.
Restricted to NumberSorts, those `Sort`s whose `eltype` isa `Number`.
"""
struct NumberConstant{T<:Number, S} <: AbstractOperator
    value::T
    sort::S # value isa eltype(sort) #~ where is this checked?
    # pnml Schema allows a SubTerm[], not used here.
end
sortof(nc::NumberConstant) = sortof(nc.sort) # singleton matching type of the value
basis(nc::NumberConstant) = typeof(nc.value) # multisets need type of the value

# others want the value of the value
# The operator inteface assumes this trio:
#  functor -> value() -> _evaluate that is identity (until it isn't).
(c::NumberConstant)() = value(c)
value(nc::NumberConstant) = _evaluate(nc) #! TODO term rewrite
_evaluate(nc::NumberConstant) = nc.value  #! TODO term rewrite
