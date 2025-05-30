"""
    DotSort
Built-in sort whose `eltype` is `Bool`, the smallest Integer subtype that can represent one.
"""
@auto_hash_equals struct DotSort <: AbstractSort
    declarationdicts::DeclDict
end

decldict(s::DotSort) = s.declarationdicts
Base.eltype(::Type{<:DotSort}) = Bool # What would be iterated over. See `sortelements`.
sortelements(s::DotSort) = tuple(PNML.DotConstant(decldict(s))) # DotConstant is an AbstractOperator
