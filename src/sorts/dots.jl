# dot sort operators

"""
Built-in sort whose `eltype` is `Bool`, the smallest Integer subtype that can represent one.
"""
@auto_hash_equals struct DotSort <: AbstractSort end
Base.eltype(::Type{<:DotSort}) = Bool # What would be iterated over. See `sortelements`.
sortelements(::DotSort) = tuple(DotConstant())

"""
    DotConstant()
Duck-typed as AbstractOperator.
"""
struct DotConstant end
sortref(::DotConstant) = usersort(:dot)
sortof(::DotConstant) = sortdefinition(namedsort(:dot))
(d::DotConstant)() = 1 # true is a number, one
toexpr(c::DotConstant) = DotConstant()
