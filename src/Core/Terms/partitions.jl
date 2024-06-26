s = """
<declaration>
<text>
    Without the following structure this Symmetric net
    example will not be a structurally conformant High-level Petri Net.
</text>
<structure>
    <declarations>
        <!-- Sorts declaration -->
        <namedsort id="usersnamed" name="USERS">
            <finiteenumeration>
                <feconstant id="apacheId" name="apache" />
                <feconstant id="iisId" name="iis" />
                <feconstant id="chrisId" name="chris" />
                <feconstant id="deniseId" name="denise" />
                <feconstant id="rootId" name="root" />
            </finiteenumeration>
        </namedsort>

        <partition id="accessrightId" name="AccessRight">
            <usersort declaration="usersnamed" />
            <partitionelement id="wwwId" name="www">
                <useroperator declaration="apacheId" />
                <useroperator declaration="iisId" />
            </partitionelement>
            <partitionelement id="workId" name="work">
                <useroperator declaration="chrisId" />
                <useroperator declaration="deniseId" />
            </partitionelement>
            <partitionelement id="adminId" name="admin">
                <useroperator declaration="rootId" />
            </partitionelement>
        </partition>


    </declarations>
</structure>
"""

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Establishes an equivalence class over a [`PartitionSort`](@ref)'s emumeration.
See also [`FiniteEnumerationSort`](@ref).
Gives a name to an element of a partition. The element is an equivalence class.
PartitionElement is different from FiniteEnumeration, CyclicEnumeration, FiniteIntRangeSort
in that it holds UserOperators, not FEConstants.
The UserOperator refers to the FEConstants of the sort over which the partition is defined.
NB: The PartitionElementOf operator maps each element of the type (aka sort) associated
with the partition to the partition element to which it belongs.

Want: PartitionElementOf(feconstant) -> id of the equivalence class

#TODO Somehow PartitionElementOf will need to make the connection.
"""
struct PartitionElement{T<:AbstractTerm} <: OperatorDeclaration # AbstractOperator
    id::Symbol
    name::Union{String,SubString{String}}
    # Note the Schema just lists one or more Terms.

    terms::Vector{T} # 1 or more, IDREF to feconstant in parent partitions's referenced sort
    #todo verify in parent partitions's referenced sort
    ids::Tuple
end
#PartitionElement() = PartitionElement(:empty, "EMPTY", UserOperator[], (:NN,))
PartitionElement(id::Symbol, name::AbstractString, terms::Vector; ids::Tuple) =
    PartitionElement(id, name, terms, ids)

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Partition sort declaration is a finite enumeration that is partitioned into sub-ranges of enumerations.
Is the sort at the partition or the element level (1 sort ot many sorts?)

"""
struct PartitionSort{S <: AbstractSort, PE <: PartitionElement} <: SortDeclaration
    id::Symbol # Schema OpDecl is id, name
    name::Union{String, SubString{String}}
    def::S # Refers to a NamedSort, will be CyclicEnumeration, FiniteEnumeration, FininteIntRange
    element::Vector{PE} # 1 or more PartitionElements that index into `def`
    ids::Tuple
end
PartitionSort() =
    PartitionSort(:partitionsort, "Empty PartitionSort", DotSort(),  PartitionElement[], (:emptypartition,))
PartitionSort(id::Symbol, name::AbstractString, sort::AbstractSort, els::Vector; ids::Tuple) =
    PartitionSort(id, name, sort,  els, ids)

sortof(partition::PartitionSort) = partition.def
elements(partition::PartitionSort) = partition.element

# TODO Add Partition/PartitionElement methods here
# list PartitionElement ids & names
# list PartitionElement terms
# access by partition id, element id

"Iterator over partition element PNML IDs"
function element_ids(ps::PartitionSort, netid::Symbol)
    Iterators.map(pid, elements(ps))
end
"Iterator over partition element names"
function element_names(ps::PartitionSort, netid::Symbol)
    Iterators.map(name, elements(ps))
end

function Base.show(io::IO, ps::PartitionSort)

        println(io, nameof(typeof(ps)), "(", pid(ps), ", ", repr(name(ps)), ",", )
        io = inc_indent(io)
        println(io, indent(io), sortof(ps), ",");
        print(io, "FE[")
        e = elements(ps)
        for  (i, c) in enumerate(e)
            print(io, '\n', indent(io)); show(io, c);
            i < length(e) && print(io, ",")
        end
        print(io, "])")
    end
