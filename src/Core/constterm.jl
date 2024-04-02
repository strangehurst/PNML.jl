# Bits that are used to build sorts and terms.

"""
    FEConstant
Finite enumeration constant.
In some cases the partition element cannot be derived from the subterms of PartitionElementOf operator.
#~ Ways to locate the partition element: (netid, partition_id), or add parent references.
"""
const FEConstant = @NamedTuple begin
    id::Symbol
    name::Union{String, SubString{String}}
    netid::Symbol  #TODO ids::Tuple
    partid::Symbol
end
#const FEConstant = @NamedTuple{id::Symbol, name::Union{String, SubString{String}}}
