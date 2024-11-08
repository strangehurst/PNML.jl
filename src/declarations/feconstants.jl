"""
    FEConstant

Finite enumeration constant.

# Usage
    fec = FEConstant(:anID, "somevalue", :sortrefid)
    fec() == "somevalue"
"""
struct FEConstant <: OperatorDeclaration
    id::Symbol # ID is unique within net.
    name::Union{String, SubString{String}} # Must name be unique within a sort?
    refid::REFID # of contining partition, enumeration, (and partitionelement?)
end

sortref(fec::FEConstant) = usersort(fec.refid)
Base.eltype(::FEConstant) = FEConstant

(fec::FEConstant)() = fec.name #! todo toexpr()

sortof(fec::FEConstant) = begin
    # These sort declarations share behavior in attaching
    # an ID and name to a component or components. These components have
    # separate dictionarys in the `DECLDICT`.
    if has_namedsort(fec.refid)
        sortdefinition(namedsort(fec.refid))::EnumerationSort
    elseif has_partitionsort(fec.refid)
        sortdefinition(partitionsort(fec.refid))::PartitionSort
    else
        # partition element?
        error("could not find a sortof REFID in ", repr(fec))
    end
end

function Base.show(io::IO, fec::FEConstant)
    print(io, nameof(typeof(fec)), "(", repr(pid(fec)), ", ", repr(fec()), ", ", repr(fec.refid), ")")
end
