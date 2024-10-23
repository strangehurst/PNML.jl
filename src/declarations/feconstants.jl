"""
    FEConstant

Finite enumeration constant.

# Usage
    fec = FEConstant(:anID, "somevalue")
    fec() == "somevalue"
"""
struct FEConstant <: OperatorDeclaration
    id::Symbol # ID is unique within net.
    name::Union{String, SubString{String}} # Must name be unique within a sort?
    #todo refid::REFID # of contining partition, partitionelement, enumeration
end

(fec::FEConstant)() = fec.name #! rewrite term _evaluate maketerm/toexpr

function Base.show(io::IO, fec::FEConstant)
    print(io, nameof(typeof(fec)), "(", repr(pid(fec)), ", ", repr(fec()), ")")
end
