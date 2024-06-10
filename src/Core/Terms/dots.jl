# dot sort operators

"""
Built-in sort whose `eltype` is `Int`
"""
@auto_hash_equals struct DotSort <: AbstractSort end
Base.eltype(::Type{<:DotSort}) = Int
elements(ds::DotSort) = tuple(dotconstant)

struct DotConstant <:AbstractOperator end
sortof(::DotConstant) = DotSort()
(d::DotConstant)() = 1 #TODO what kind of one?
const dotconstant = DotConstant()
