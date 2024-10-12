#= Example from sampleSNPrio.pnml
<declaration>
<text>F
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
=#

"""
    PartitionElement(id::Symbol, name, Vector{IDREF})

$(TYPEDFIELDS)

Establishes an equivalence class over a [`PNML.Declarations.PartitionSort`](@ref)'s emumeration.
See also [`FiniteEnumerationSort`](@ref).
Gives a name to an element of a partition. The element is an equivalence class.

PartitionElement is different from FiniteEnumeration, CyclicEnumeration, FiniteIntRangeSort
in that it holds UserOperators, not FEConstants.
The UserOperator refers to the FEConstants of the sort over which the partition is defined.
NB: FEConstants are 0-arity operators.
UserOperator is how operation declarations are accessed.

NB: The "PartitionElementOf" operator maps each element of the FiniteEnumeration
(referenced by the partition) to the PartitionElement (of the partition) to which it belongs.

PartitionElementOf(partition, feconstant) -> PartitionElement
partitionelementof(partition, feconstant) -> PartitionElement

PartitionElementOf is passed a REFID of the partition whose
PartitionElement membership is being queried.

Each PartitionElement contains a collection of REFIDs to UserOperators which refer to
a finite sort's (FiniteEnumeration, CyclicEnumeration, FiniteIntRangeSort) FEConstant by REFID.

Test for membership by iterating over each partition element, and over each term.
"""
struct PartitionElement <: OperatorDeclaration
    id::Symbol
    name::Union{String,SubString{String}}
    terms::Vector{REFID} # 1 or more, feconstant in parent partitions's referenced sort
    #todo verify terms are in parent partitions's referenced sort
end


"""
$(TYPEDEF)
$(TYPEDFIELDS)

Partition sort declaration is a finite enumeration that is partitioned into sub-ranges of enumerations.
Is the sort at the partition or the element level (1 sort or many sorts?)

Like [`NamedSort`](@ref), will add an `id` and `name` to a sort, however,
it used indirection via a `UserSort`.
"""
struct PartitionSort <: SortDeclaration
    id::Symbol
    name::Union{String, SubString{String}}
    def::REFID # like UserSort REFID refers to a sort declaration (NamedSort) that wraps, FiniteEnumeration, CyclicEnumeration, FiniteIntRange
    elements::Vector{PartitionElement} # 1 or more PartitionElements that index into `def` #TODO a set?

    function PartitionSort(i,n,d,e)
        # Assert that `d` leads to proper sortdefinition wrapped in a namedsort.
        has_namedsort(d) || throw(ArgumentError("REFID $d is not a NamedSort"))
        # Look at what is wrapped.
        tag(sortdefinition(namedsort(d))) in (:finiteenumeration, :cyclicenumeration, :finiteintenumeration)
        new(i,n,d,e)
    end
end
PartitionSort() = PartitionSort(:partition, "Empty Partition", :dot,  PartitionElement[])
#! :dot is a stand-in, it will not work well, but it is a "finite sort".

#TODO also do AbstractSort?
sortdefinition(partition::PartitionSort) = sortdefinition(namedsort(partition.def)) #! what is the sort of a partition
sortelements(partition::PartitionSort) = partition.elements

# TODO Add Partition/PartitionElement methods here
# list PartitionElement ids & names
# list PartitionElement terms
# access by partition id, element id

"Iterator over partition element PNML IDs"
function element_ids(ps::PartitionSort, netid::Symbol)
    Iterators.map(pid, sortelements(ps))
end

"Iterator over partition element names"
function element_names(ps::PartitionSort, netid::Symbol)
    Iterators.map(name, sortelements(ps))
end

function Base.show(io::IO, ps::PartitionSort)
    println(io, nameof(typeof(ps)), "(", pid(ps), ", ", repr(name(ps)), ",", )
    io = inc_indent(io)
    println(io, indent(io), sortdefinition(ps), ",");
    print(io, "FE[")
    e = sortelements(ps)
    for  (i, c) in enumerate(e)
        print(io, '\n', indent(io)); show(io, c);
        i < length(e) && print(io, ",")
    end
    print(io, "])")
end
