# user sort
"""
$(TYPEDEF)

Holds a reference id (REFID) to a subtype of `SortDeclaration` stored in a `DeclDict`.

[`PNML.Declarations.NamedSort`](@ref) is used to construct a sort out of builtin sorts.
Also [`PNML.Declarations.ArbitrarySort`](@ref), [`PNML.Declarations.PartitionSort`](@ref).
"""
@auto_hash_equals fields=declaration struct UserSort <: AbstractSort
    declaration::REFID #TODO validate REFID in `DeclDict`
    declarationdicts::DeclDict
end

# `<productsort>` defines a tuple of sorts.
# Related to PNML `<tuple>` operator) that returns a Julia `tuple` of elements of sorts.
# `<variabledecl` links a sort with a name & REFID. `<variable` accesses by REFID.

#? todo is the name the unique identifier of a variable?

# ePNK uses `<namedoperator>` `<parameter>` `<variabledecl` to map the ordered arguments
# to the expression variables in `<def>`
# and for `<place><type>` label `<structure>`.

#! Can also be ProductSort, MultisetSort. ePNK uses inline sorts.

#! Sorts can be inline in a variabledecl as part of useroperator, sorttype (anywhere else?)
#! They will be concrete types.
#! no dynamic behavior re embedded sorts during enabling/firing rules. (treat as constant)
#! cache any values that need calculating
#! want to use REFIDs to avoid the need to define Types.

#^ productsort is a tuple of 0 or more sorts
#^ may nest productsort in a productsort (not true for multisetsort)
#^ see also multisetsort that has a basis sort (that can be a productsort)

#~ We create user/named duos for each built-in sort.

refid(us::UserSort) = us.declaration::Symbol # Of `namedsort`, `partitionsort`, `arbitrarysort`
decldict(us::UserSort) = us.declarationdicts

"Get NamedSort from UserSort REFID"
namedsort(us::UserSort) = namedsort(decldict(us), refid(us))::PNML.Declarations.NamedSort #todo partitionsort, arbitrarysort
sortref(us::UserSort) = identity(us)::AbstractSortRef
function sortof(us::UserSort)
    #@show namedsort(us) #! debug
    sortdefinition(namedsort(us)) #^ ArbitrarySort, PartitionSort, ProductSort
end
Base.eltype(us::UserSort) = eltype(sortof(us))

# Forward operations to the NamedSort matching the declaration REFID.
function sortelements(us::UserSort)
    ns = namedsort(us) #todo can be partitionsort, arbitrarysort sort declaration.
    sortelements(ns)
end


name(us::UserSort) = name(namedsort(us))

function Base.show(io::IO, us::UserSort)
    print(io, PNML.indent(io), "UserSort(", repr(refid(us)), ")")
end

isproductsort(us::UserSort) = isa(sortdefinition(namedsort(us)), ProductSort)
