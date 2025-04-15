"""
    DotSort
Built-in sort whose `eltype` is `Bool`, the smallest Integer subtype that can represent one.
"""
@auto_hash_equals struct DotSort <: AbstractSort end
Base.eltype(::Type{<:DotSort}) = Bool # What would be iterated over. See `sortelements`.
sortelements(::DotSort) = tuple(PNML.DotConstant()) # DotConstant is an AbstractOperator
