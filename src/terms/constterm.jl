"""
    NumberConstant{T<:Number, S}

Builtin operator that has arity=0 means the same result every time, a constant.
Restricted to NumberSorts, those `Sort`s whose `eltype` isa `Number`.
"""
struct NumberConstant{T<:Number,} <: AbstractOperator
    value::T
    sort::UserSort # value isa eltype(sort), verified by parser.
    declarationdicts::DeclDict
    # Constant operators are 0-arity by definition. Parameter vector not used here.
end

decldict(nc::NumberConstant) = nc.declarationdicts
sortref(nc::NumberConstant) = identity(nc.sort)::UserSort
basis(nc::NumberConstant)   = sortref(nc.value)::UserSort
sortof(nc::NumberConstant) = sortdefinition(namedsort(decldict(nc), sortref(nc)))

# others want the value of the value
(c::NumberConstant)() = value(c)
value(nc::NumberConstant) = nc.value


"""
    FEConstant

Finite enumeration constant.

# Usage
    fec = FEConstant(:anID, "somevalue", :sortrefid)
    fec() == :anID
    fec.name = "somevalue"
"""
struct FEConstant <: AbstractOperator
    id::Symbol # ID is unique within net.
    name::Union{String, SubString{String}} # Must name be unique within a sort?
    refid::REFID # of contining partition, enumeration, (and partitionelement?)
    declarationdicts::DeclDict
end

decldict(fec::FEConstant) = fec.declarationdicts
refid(fec::FEConstant) = fec.refid
sortref(fec::FEConstant) = PNML.usersort(decldict(fec), fec.refid)::UserSort
Base.eltype(::FEConstant) = Symbol # Use id symbol as the value.

(fec::FEConstant)(args) = fec() # Constants are 0-ary operators. Ignore arguments.
(fec::FEConstant)() = fec.id # A constant literal. We use symbol, could use string.

sortof(fec::FEConstant) = begin
    # Search on REFID of containing sort defintion.
    # These share behavior in attaching an ID and name to a component or components.
    # These components have seperate dictionaries in the `DeclDict`.
    if PNML.has_namedsort(decldict(fec), fec.refid)
        sortdefinition(namedsort(decldict(fec), fec.refid))::EnumerationSort
    elseif PNML.has_partitionsort(decldict(fec), fec.refid)
        sortdefinition(partitionsort(decldict(fec), fec.refid))::PartitionSort
        # Partitions are over a single EnumerationSort
    else
        # partition element?
        error("could not find a sortof REFID in ", repr(fec))
    end
end

function Base.show(io::IO, fec::FEConstant)
    print(io, nameof(typeof(fec)), "(", repr(fec.id), ", ", repr(fec.name), ", ", repr(fec.refid), ")")
end


"""
    $(TYPEDEF)
Must refer to a value between the start and end of the respective `FiniteIntRangeSort`.
"""
struct FiniteIntRangeConstant{T<:Integer} <: AbstractOperator
    value::T
    sort::UserSort # wrapping a FiniteIntRangeSort
    declarationdicts::DeclDict
    #TODO! Assert that T is a sort eltype.
end
tag(::FiniteIntRangeConstant) = :finiteintrangeconstant
decldict(c::FiniteIntRangeConstant) = c.declarationdicts

# FIRconstants have an embedded sort definition, NOT a namedsort or usersort.
# We create a usersort, namedsort duo to match. Is expected to be an IntegerSort.
sortref(c::FiniteIntRangeConstant) = identity(c.sort)::UserSort

"Special case to ` IntegerSort()`, it is part of the name, innit."
sortof(c::FiniteIntRangeConstant) = IntegerSort() # FiniteIntRangeConstant are always integers
# or sortdefinition(namedsort(ddict, :integer))::IntegerSort

value(c::FiniteIntRangeConstant) = c.value
(c::FiniteIntRangeConstant)() = value(c)


"""
The only element of `DotSort` is `DotConstant`.
"""
struct DotConstant <: AbstractOperator
    declarationdicts::DeclDict
end
decldict(dc::DotConstant) = dc.declarationdicts
sortref(::DotConstant) = usersort(:dot)::UserSort
sortof(::DotConstant) = sortdefinition(namedsort(decldict(dc), :dot))
(d::DotConstant)() = 1 # true is a number, one

function Base.show(io::IO, c::DotConstant)
    print(io, nameof(typeof(c)), "()") # Exclude declarationdicts
end

"""
    BooleanConstant("true"|"false", decldict) is a built-in operator (constants are 0-ary operators).
    c = BooleanConstant(true, decldict); c() == true
"""
struct BooleanConstant <: AbstractOperator
    value::Bool
    declarationdicts::DeclDict
end

function BooleanConstant(s::Union{AbstractString,SubString{String}}, ddict::DeclDict)

    BooleanConstant(parse(eltype(sortdefinition(namedsort(ddict, :bool))), s), ddict)
end

decldict(dc::BooleanConstant) = dc.declarationdicts
tag(::BooleanConstant) = :booleanconstant
sortref(::BooleanConstant) = usersort(:bool)::UserSort
sortof(bc::BooleanConstant) = sortdefinition(namedsort(decldict(bc), :bool))

(c::BooleanConstant)() = value(c)
value(bc::BooleanConstant) = bc.value

function Base.show(io::IO, c::BooleanConstant)
    print(io, nameof(typeof(c)), "(", value(c), ")")
end
