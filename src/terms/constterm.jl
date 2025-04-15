"""
    NumberConstant{T<:Number, S}

Builtin operator that has arity=0 means the same result every time, a constant.
Restricted to NumberSorts, those `Sort`s whose `eltype` isa `Number`.
"""
struct NumberConstant{T<:Number} <: AbstractOperator #todo put all constant operators here
    value::T
    sort::UserSort # value isa eltype(sort), verified by parser.
    # pnml Schema allows a SubTerm[], not used here.
end

sortref(nc::NumberConstant) = identity(nc.sort)::UserSort
sortof(nc::NumberConstant) = sortdefinition(namedsort(sortref(nc)))
basis(nc::NumberConstant) = typeof(nc.value) # multisets need type of the value

# others want the value of the value
(c::NumberConstant)() = value(c)
value(nc::NumberConstant) = nc.value
toexpr(nc::NumberConstant, ::NamedTuple) = value(nc)


"""
    FEConstant

Finite enumeration constant.

# Usage
    fec = FEConstant(:anID, "somevalue", :sortrefid)
    fec() == :anID
    fec.name = "somevalue"
"""
struct FEConstant <: AbstractOperator # 2025-04-14 move to term/constterm.jl
    id::Symbol # ID is unique within net.
    name::Union{String, SubString{String}} # Must name be unique within a sort?
    refid::REFID # of contining partition, enumeration, (and partitionelement?)
end
refid(fec::FEConstant) = fec.refid
sortref(fec::FEConstant) = PNML.usersort(fec.refid)::UserSort
Base.eltype(::FEConstant) = Symbol # Use id symbol as the value.

(fec::FEConstant)(args) = fec() # Constants are 0-ary operators. Ignore arguments.
(fec::FEConstant)() = fec.id # A constant literal. We use symbol, could use string.

sortof(fec::FEConstant) = begin
    # Search on REFID of containing sort defintion.
    # These share behavior in attaching an ID and name to a component or components.
    # These components have seperate dictionaries in the `DECLDICT`.
    if PNML.has_namedsort(fec.refid)
        sortdefinition(namedsort(fec.refid))::EnumerationSort
    elseif PNML.has_partitionsort(fec.refid)
        sortdefinition(partitionsort(fec.refid))::PartitionSort
        # Partitions are over a single EnumerationSort
    else
        # partition element?
        error("could not find a sortof REFID in ", repr(fec))
    end
end

function Base.show(io::IO, fec::FEConstant)
    print(io, nameof(typeof(fec)), "(", repr(pid(fec)), ", ", repr(fec()), ", ", repr(fec.refid), ")")
end


"""
    $(TYPEDEF)
Must refer to a value between the start and end of the respective `FiniteIntRangeSort`.
"""
struct FiniteIntRangeConstant{T<:Integer} # <: AbstractOperator #todo move to term/constterm.jl
    value::T
    sort::UserSort # wrapping a FiniteIntRangeSort
    #TODO! Assert that T is a sort eltype.
end
tag(::FiniteIntRangeConstant) = :finiteintrangeconstant

# FIRconstants have an embedded sort definition, NOT a namedsort or usersort.
# We create a usersort, namedsort duo to match. Is expected to be an IntegerSort.
sortref(c::FiniteIntRangeConstant) = identity(c.sort)::UserSort
sortof(c::FiniteIntRangeConstant) = IntegerSort() # FiniteIntRangeConstant are always integers

value(c::FiniteIntRangeConstant) = c.value
(c::FiniteIntRangeConstant)() = value(c)
PNML.toexpr(c::FiniteIntRangeConstant, ::NamedTuple) = value(c)
