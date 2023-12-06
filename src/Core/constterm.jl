# Bits that are used to build sorts and terms.
struct FEConstant
    id::Symbol
    name::String
end

function Base.show(io::IO, fec::FEConstant)
    print(io, "FEConstant(");
    show(io, fec.id); print(io, ", ")
    show(io, fec.name)
    print(io, ")")
end
