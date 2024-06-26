abstract type NumberSort <: AbstractSort end

"""
Built-in sort whose `eltype` is `Int`
"""
@auto_hash_equals struct IntegerSort <: NumberSort end
Base.eltype(::Type{<:IntegerSort}) = Int
(i::IntegerSort)() = 1
const integersort = IntegerSort()

"""
Built-in sort whose `eltype` is `Int`
"""
@auto_hash_equals struct NaturalSort <: NumberSort end
Base.eltype(::Type{<:NaturalSort}) = Int # Uint ?
const naturalsort = NaturalSort()

"""
Built-in sort whose `eltype` is `Int`
"""
@auto_hash_equals struct PositiveSort <: NumberSort end
Base.eltype(::Type{<:PositiveSort}) = Int # Uint ?
const positivesort = PositiveSort()

"""
Built-in sort whose `eltype` is `Float64`
"""
@auto_hash_equals struct RealSort <: NumberSort end
Base.eltype(::Type{<:RealSort}) = Float64
const realsort = RealSort()

"""
Built-in sort whose `eltype` is `Nothing`
"""
@auto_hash_equals struct NullSort <: NumberSort end
Base.eltype(::Type{<:NullSort}) = Nothing
const nullsort = NullSort()

"""
Builtin operator that has arity=0 means the same result every time, a constant.
Restricted to NumberSorts, those `Sort`s whose `eltype` isa `Number`.
"""
struct NumberConstant{T<:Number, S<:NumberSort} <: AbstractOperator
    value::T
    sort::S # value isa eltype(sort)
    # Schema allows a SubTerm[], Not used here. Part of pnml generic operator xml structure?
end
sortof(nc::NumberConstant) = nc.sort
basis(nc::NumberConstant) = typeof(nc.value)
value(nc::NumberConstant) = _evaluate(nc)
_evaluate(nc::NumberConstant) = nc.value
(c::NumberConstant)() = value(c)
