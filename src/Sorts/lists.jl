"""
$(TYPEDEF)
"""
@auto_hash_equals struct ListSort{T<:AbstractSortRef} <: AbstractSort
    basis::T
    #!declarationdicts::DeclDict
end

#    basissort = parse_sort(Val(tag), basisnode, pntd, nothing, ""; net)::AbstractSortRef # of multisetsort


equal(a::ListSort, b::ListSort) = a.basis == b.basis

function Base.show(io::IO, s::ListSort)
    print(io, "ListSort(", basis, ")")
end
