"""
$(TYPEDEF)
$(TYPEDFIELDS)

Establishes an equivalence class over a [`PartitionSort`](@ref)'s emumeration. See also [`FiniteEnumerationSort`](@ref).
Gives a name to an element of a partition. The element is an equivalence class.
PartitionElement is different from FiniteEnumeration, CyclicEnumeration, FiniteIntRangeSort
in that it holds UserOperators, not FEConstants.
The UserOperator refers to the FEConstants of the sort over which the partition is defined.
NB: The PartitionElementOf operator maps each element of the type (aka sort) associated
with the partition to the partition element to which it belongs.

Want: PartitionElementOf(feconstant) -> id of the equivalence class

#TODO Somehow PartitionElementOf will need to make the connection.
"""
struct PartitionElement # AbstractOperator
    id::Symbol
    name::Union{String,SubString{String}}
    # Note the Schema just lists one or more Terms.
    terms::Vector{UserOperator} # 1 or more constants: feconstant(decldict(netid), tag(namedop))
    partid::Symbol # the PartitionSort so we can access it via decldict. #~ Or do a binding.
    #ids::
end
PartitionElement() = PartitionElement(:partitionelement, "Empty Partition Element", UserOperator[])

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Partition sort declaration is a finite enumeration that is partitioned into sub-ranges of enumerations.
Is the sort at the partition or the element level (1 sort ot many sorts?)

"""
struct PartitionSort{S <: AbstractSort, PE <: PartitionElement} <: SortDeclaration
    id::Symbol # Schema OpDecl is id, name
    name::Union{String,SubString{String}}
    def::S # Refers to a NamedSort, will be CyclicEnumeration, FiniteEnumeration, FininteIntRange
    element::Vector{PE} # 1 or more PartitionElements that index into `def`
    #
end
PartitionSort() = PartitionSort(:partitionsort, "Empty PartitionSort", DotSort(),  PartitionElement[])
sort(partition::PartitionSort) = partition.def
elements(partition::PartitionSort) = partition.element

# TODO Add Partition/PartitionElement methods here
# list PartitionElement ids & names
# list PartitionElement terms
# access by partition id, element id
