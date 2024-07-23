"""
$(TYPEDEF)
"""
@auto_hash_equals struct StringSort <: AbstractSort
    ae::Vector{AbstractSort}
end
StringSort() = StringSort(IntegerSort[])

function Base.show(io::IO, s::StringSort)
    print(io, "StringSort([")
    io = inc_indent(io)
    for  (i, c) in enumerate(s.ae)
        print(io, '\n', indent(io)); show(io, c);
        i < length(s.ae) && print(io, ",")
    end
    print(io, "])")
end
