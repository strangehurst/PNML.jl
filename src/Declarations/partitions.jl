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
    PartitionElement(id::Symbol, name, Vector{IDREF}, REFID)

$(TYPEDFIELDS)

Establishes an equivalence class over a [`Declarations.PartitionSort`](@ref)'s emumeration.
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
    terms::Vector{REFID} # 1 or more ref to feconstant in partitions's referenced sort.
    partition::REFID
    declarationdicts::DeclDict
    #todo verify terms are in parent partitions's referenced sort
end

"Return Bool true if partition contains the FEConstant"
function contains end
contains(pe::PartitionElement, fec::REFID) = fec in pe.terms

function Base.show(io::IO, pe::PartitionElement)
    print(io, nameof(typeof(pe)), "(", pid(pe), ", ", repr(name(pe)), ", ")
    show(io,  pe.terms)
    print(io, ", ",  repr(pe.partition), ")")
 end

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Partition sort declaration is a finite enumeration that is partitioned into sub-ranges of enumerations.
Is the sort at the partition or the element level (1 sort or many sorts?)

Like [`NamedSort`](@ref), will add an `id` and `name` to a sort, and is accessed by `UserSort`.
"""
struct PartitionSort{S <: AbstractSortRef} <: SortDeclaration
    id::Symbol
    name::Union{String, SubString{String}}
    def::S # Like a NamedSort, refers to a sort (EnumerationSort)
    elements::Vector{PartitionElement} # 1 or more PartitionElements that index into `def` #TODO a set?
    declarationdicts::DeclDict

    # function PartitionSort(i, n, d, e, dd)
    #     # PNML.has_namedsort(d) || throw(ArgumentError("REFID $(repr(d)) is not a NamedSort"))
    #     # # Look at what is wrapped.
    #     # @assert PNML.tag(sortdefinition(PNML.namedsort(d))) in (:finiteenumeration, :cyclicenumeration, :finiteintenumeration)
    #     new(i, n, d, e, dd)
    # end
end

decldict(p::PartitionSort) = p.declarationdicts

#TODO also do AbstractSort, another SortDeclaration
sortdefinition(p::PartitionSort) = sortdefinition(PNML.namedsort(decldict(p), refid(p.def)))
sortelements(p::PartitionSort) = p.elements

# TODO Add Partition/PartitionElement methods here
# list PartitionElement ids & names
# list PartitionElement terms
# access by partition id, element id

"Iterator over partition element REFIDs of a `PartitionSort"
function element_ids(ps::PartitionSort, netid::Symbol)
    Iterators.map(pid, sortelements(ps))
end

"Iterator over partition element names"
function element_names(ps::PartitionSort, netid::Symbol)
    Iterators.map(name, sortelements(ps))
end

function Base.show(io::IO, ps::PartitionSort)
    println(io, nameof(typeof(ps)), "(", pid(ps), ", ", repr(name(ps)), ", ", repr(ps.def), ",")
    io = PNML.inc_indent(io)
    print(io, PNML.indent(io), "[")
    e = sortelements(ps)
    for  (i, c) in enumerate(e)
        show(io, c)
        i < length(e) && print(io, ",\n", PNML.indent(io), " ")
    end
    print(io, "])")
end
