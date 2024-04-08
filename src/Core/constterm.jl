# Bits that are used to build sorts and terms.

"""
    FEConstant
Finite enumeration constant.
In some cases the partition element cannot be derived from the subterms of PartitionElementOf operator.
#~ Ways to locate the partition element: (netid, partition_id), or add parent references.
"""
struct FEConstant <: OperatorDeclaration
    id::Symbol
    name::Union{String, SubString{String}} # value, redundant with ID?
    netid::Symbol  #TODO ids::Tuple
    #partid::Symbol #~ is this knowable?
end
