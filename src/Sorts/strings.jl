"""
$(TYPEDEF)

"""
@auto_hash_equals struct StringSort <: AbstractSort
    declarationdicts::DeclDict
end
Base.eltype(::Type{<:StringSort}) = String
sortelements(::StringSort) = tuple("") # default element is empty string
