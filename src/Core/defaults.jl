"""
$(TYPEDSIGNATURES)
Return default condition based on `PNTD`. Has meaning of true or always.
```
"""
function default_condition end
default_condition(x::Any) = error("no default condition for $(typeof(x))")

"""
$(TYPEDSIGNATURES)
Return default inscription value based on `PNTD`. Has meaning of unity, as in `one`.
"""
function default_inscription end
default_inscription(x::Any) = error("no default inscription for $(typeof(x))")

"""
$(TYPEDSIGNATURES)
Return default marking value based on `PNTD`. Has meaning of empty, as in `zero`.
"""
function default_marking end
default_marking(x::Any) = error("no default marking for $(typeof(x))")

"""
$(TYPEDSIGNATURES)
Return instance of default sort based on `PNTD`.
"""
function default_sort end
default_sort(x::Any) = error("no default sort defined for $(typeof(x))")
default_sort(pntd::PnmlType) = default_sort(typeof(pntd))
default_sort(::Type{T})  where {T <: PnmlType} = default_sort_type(T)()

"""
$(TYPEDSIGNATURES)
Return instance of default place sort type based on `PNTD`.
"""
function default_sorttype end
default_sorttype(x::Any) = error("no default sorttype defined for $(typeof(x))")
default_sorttype(pntd::PnmlType) = default_sorttype(typeof(pntd))
default_sorttype(::Type{T}) where {T<:PnmlType} = SortType("default", default_sort(T))

"""
$(TYPEDSIGNATURES)
"""
function default_sort_type end
default_sort_type(x::Any) = error("no default_sort_type defined for $(typeof(x))")
default_sort_type(pntd::PnmlType)     = default_sort_type(typeof(pntd))
default_sort_type(::Type{<:PnmlType}) = IntegerSort
default_sort_type(::Type{<:AbstractContinuousNet}) = RealSort

sorttype_type(::Type{T}) where {T <: PnmlType} = eltype(default_sort(T))

#------------------------------------------------------------------------------
default_condition(::PnmlType)   = Condition(true)
default_inscription(::PnmlType) = Inscription(one(Int))
default_marking(::PnmlType)     = Marking(zero(Int))

#------------------------------------------------------------------------------
default_condition(::AbstractContinuousNet)   = Condition(true)
default_inscription(::AbstractContinuousNet) = Inscription(one(Float64))
default_marking(::AbstractContinuousNet)     = Marking(zero(Float64))
