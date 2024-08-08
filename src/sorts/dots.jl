# dot sort operators

"""
Built-in sort whose `eltype` is `Int`
"""
@auto_hash_equals struct DotSort <: AbstractSort end
Base.eltype(::Type{<:DotSort}) = Int
sortelements(::DotSort) = tuple(DotConstant())

"""
    DotConstant()
Duck-typed as AbstractOperator.
"""
struct DotConstant end
sortof(::DotConstant) = sortof(namedsort(:dot))
(d::DotConstant)() = 1 #TODO what kind of one?
