"""
$(TYPEDEF)

"""
@auto_hash_equals struct StringSort <: AbstractSort end
Base.eltype(::Type{<:StringSort}) = String
sortelements(::StringSort) = tuple("")
