abstract type NumberSort <: AbstractSort end

"""
Built-in sort whose `eltype` is `Int`
"""
@auto_hash_equals struct IntegerSort <: NumberSort end
Base.eltype(::Type{<:IntegerSort}) = Int
(i::IntegerSort)() = 1
sortelements(::Type{<:IntegerSort}) = Iterators.countfrom(0, 1)
sortelements(::IntegerSort) = Iterators.countfrom(0, 1)
refid(::IntegerSort) = :integer

"""
Built-in sort whose `eltype` is `Int`
"""
@auto_hash_equals struct NaturalSort <: NumberSort end
Base.eltype(::Type{<:NaturalSort}) = Int # Uint ?
sortelements(::Type{<:NaturalSort}) = Iterators.countfrom(0, 1)
sortelements(::NaturalSort) = Iterators.countfrom(0, 1)
refid(::NaturalSort) = :natural

"""
Built-in sort whose `eltype` is `Int`
"""
@auto_hash_equals struct PositiveSort <: NumberSort end
Base.eltype(::Type{<:PositiveSort}) = Int # Uint ?
sortelements(::Type{<:PositiveSort}) = Iterators.countfrom(1, 1)
sortelements(::PositiveSort) = Iterators.countfrom(1, 1)
refid(::PositiveSort) = :positive

"""
Built-in sort whose `eltype` is `Float64`
"""
@auto_hash_equals struct RealSort <: NumberSort end
Base.eltype(::Type{<:RealSort}) = Float64
sortelements(::Type{<:RealSort}) = Iterators.map(x->1.0*x, Iterators.countfrom(0, 1))
sortelements(::RealSort) = Iterators.map(x->1.0*x, Iterators.countfrom(0, 1))
refid(::RealSort) = :real

"""
Built-in sort whose `eltype` is `Nothing`
"""
@auto_hash_equals struct NullSort <: NumberSort end
Base.eltype(::Type{<:NullSort}) = Nothing
sortelements(::Type{<:NullSort}) = tuple() # empty
sortelements(::NullSort) = tuple() # empty
refid(::NullSort) = :null
