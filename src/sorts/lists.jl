"""
$(TYPEDEF)
"""
@auto_hash_equals struct ListSort <: AbstractSort
    #
    ae::Vector{AbstractSort} #~ ABSTRACT
end
ListSort() = ListSort(IntegerSort[])
#! equal(a::ListSort, b::ListSort) = a.ae == b.ae

function Base.show(io::IO, s::ListSort)
    print(io, "ListSort([")
    io = inc_indent(io)
    for  (i, c) in enumerate(s.ae)
        print(io, '\n', indent(io)); show(io, c);
        i < length(s.ae) && print(io, ",")
    end
    print(io, "])")
end
