"""
$(TYPEDEF)
$(TYPEDFIELDS)

Part of a [`PartitionSort`](@ref)'s emumeration. See also [`FiniteEnumerationSort`](@ref).
"""
struct PartitionElement
    id::Symbol
    name::Union{String,SubString{String}}
    terms::Vector{UserOperator} # 1 or more Terms of PatrtitionSort's (UserOperator?) as constants
end
PartitionElement() = PartitionElement(:partitionelement, "Empty Partition Element", UserOperator[])

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Partition is a finite enumeration that is partitioned into sub-ranges of enumerations.
Is the sort at the partition or the element level (1 sort ot many sorts?)
"""
struct PartitionSort{S <: AbstractSort, PE <: PartitionElement} <: SortDeclaration
    id::Symbol
    name::Union{String,SubString{String}}
    def::S # Refers to a NamedSort
    element::Vector{PE} # 1 or more PartitionElements. Each is
    #
end
PartitionSort() = PartitionSort(:partitionsort, "Empty PartitionSort", DotSort(),  PartitionElement[])
sort(partition::PartitionSort) = partition.def
elements(partition::PartitionSort) = partition.element
