"""
    NumberConstant{T<:Number, S}

Builtin operator that has arity=0 means the same result every time, a constant.
Restricted to NumberSorts, those `Sort`s whose `eltype` isa `Number`.
"""
struct NumberConstant{T<:Number, S #=<:NumberSort=#} <: AbstractOperator
    value::T
    sort::S # value isa eltype(sort)
    # pnml Schema allows a SubTerm[], Not used here.
end
sortof(nc::NumberConstant) = nc.sort
basis(nc::NumberConstant) = typeof(nc.value)
value(nc::NumberConstant) = _evaluate(nc)
_evaluate(nc::NumberConstant) = nc.value
(c::NumberConstant)() = value(c)
