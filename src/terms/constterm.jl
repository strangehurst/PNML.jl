"""
    NumberConstant{T<:Number, S}

Builtin operator that has arity=0 means the same result every time, a constant.
Restricted to NumberSorts, those `Sort`s whose `eltype` isa `Number`.
"""
struct NumberConstant{T<:Number} <: AbstractOperator
    value::T
    sort::UserSort # value isa eltype(sort), verified by parser.
    # pnml Schema allows a SubTerm[], not used here.
end
sortref(nc::NumberConstant) = nc.sort
sortof(nc::NumberConstant) = sortdefinition(namedsort(sortref(nc)))
basis(nc::NumberConstant) = typeof(nc.value) # multisets need type of the value

# others want the value of the value
# The operator inteface assumes this trio: functor -> value() -> toexpr (maybe identity).
(c::NumberConstant)() = value(c)
value(nc::NumberConstant) = nc.value
toexpr(nc::NumberConstant) = value(nc)
