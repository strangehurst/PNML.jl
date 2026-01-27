"""
    NumberConstant{T<:Number, S}

Builtin operator that has arity=0 means the same result every time, a constant.
Restricted to NumberSorts, those `Sort`s whose `eltype` isa `Number`.
"""
struct NumberConstant{T<:Number, S <: AbstractSortRef} <: AbstractOperator
    value::T
    sort::S # value isa eltype(sort), verified by parser.
    # Constant operators are 0-arity by definition. Parameter vector not used here.
end

sortref(nc::NumberConstant) = identity(nc.sort)::AbstractSortRef
basis(nc::NumberConstant)   = sortref(nc.value)::AbstractSortRef
sortof(nc::NumberConstant, net::AbstractPnmlNet) =
    sortdefinition(namedsort(decldict(net), sortref(nc)))

# others want the value of the value
(c::NumberConstant)() = value(c)
value(nc::NumberConstant) = nc.value


"""
    FEConstant

Finite enumeration constant.

> these FEConstants are part of the declaration of the FiniteEnumeration sort. On the other hand, each of
these FEConstants defines a 0-ary operation, i. e. is a declaration of a constant.

# Usage
    fec = FEConstant(:anID, "somevalue", decldict)
    fec() == :anID
    fec.name = "somevalue"
"""
struct FEConstant{S <: AbstractSortRef} <: AbstractOperator
    id::Symbol # ID is unique within net.
    name::Union{String, SubString{String}} # Must name be unique within a sort?
    ref::S # of contining partition, enumeration, (or partitionelement?)
end

refid(fec::FEConstant)    = refid(fec.ref)::Symbol
sortref(fec::FEConstant)  = fec.ref
Base.eltype(::FEConstant) = Symbol # Use id symbol as the value. Alternative is name.

(fec::FEConstant)(args) = fec() # Constants are 0-ary operators. Ignore arguments.
(fec::FEConstant)() = fec.id # A constant literal. We use symbol, could use name string.

function sortof(fec::FEConstant, net::AbstractPnmlNet)
    @match fec.ref begin
        NamedSortRef(refid) =>
            sortdefinition(namedsort(decldict(net), refid))::EnumerationSort
        PartitionSortRef(refid) =>
            sortdefinition(partitionsort(decldict(net), refid))::PartitionSort
        # Partitions are over a single EnumerationSort
        # partition element?
        _ => error("unsupported SortRef: ", repr(fec))
    end
end

function Base.show(io::IO, fec::FEConstant)
    print(io, nameof(typeof(fec)), "($(repr(fec.id)), $(repr(fec.name)))")
end

"""
    $(TYPEDEF)
Must refer to a value between the start and end of the respective `FiniteIntRangeSort`.
"""
struct FiniteIntRangeConstant{T<:Integer, S <: AbstractSortRef} <: AbstractOperator
    value::T
    sort::S
    #TODO! Assert that T is a sort eltype.
end
tag(::FiniteIntRangeConstant) = :finiteintrangeconstant

# FIRconstants have an embedded sort definition, NOT a namedsort or usersort.
# We create a namedsort duo to match. Is expected to be an IntegerSort.
sortref(c::FiniteIntRangeConstant) = identity(c.sort)::AbstractSortRef

#"Special case to ` IntegerSort()`, it is part of the name, innit."
sortof(::FiniteIntRangeConstant, ::AbstractPnmlNet) = IntegerSort() # FiniteIntRangeConstant are always integers
# or sortdefinition(namedsort(ddict, :integer))::IntegerSort

value(c::FiniteIntRangeConstant) = c.value
(c::FiniteIntRangeConstant)() = value(c)

"""
The only element of `DotSort` is `DotConstant`.
This is a 0-arity opertor term that evaluates to `1`.
"""
struct DotConstant <: AbstractOperator
end
sortref(::DotConstant) = UserSortRef(:dot)
sortof(::DotConstant, net::AbstractPnmlNet) = sortdefinition(namedsort(decldict(net), :dot))
(d::DotConstant)() = 1 # true is a number, one

function Base.show(io::IO, c::DotConstant)
    print(io, nameof(typeof(c)), "()") # Exclude declarationdicts
end

"""
    BooleanConstant("true"|"false", decldict)
    BooleanConstant(true|false)

A built-in operator (constants are 0-ary operators).

Examples
```
    c = BooleanConstant("true", decldict);
    c == BooleanConstant(true)
    c() == true
```
"""
struct BooleanConstant <: AbstractOperator
    value::Bool
end

function BooleanConstant(s::Union{AbstractString,SubString{String}}, ddict)
    BooleanConstant(parse(eltype(sortdefinition(namedsort(ddict, :bool))), s))
end

tag(::BooleanConstant) = :booleanconstant
sortref(::BooleanConstant) = UserSortRef(:bool)
sortof(::BooleanConstant, net::AbstractPnmlNet) = sortdefinition(namedsort(decldict(net), :bool))

(c::BooleanConstant)() = value(c)
value(bc::BooleanConstant) = bc.value

function Base.show(io::IO, c::BooleanConstant)
    print(io, nameof(typeof(c)), "(", value(c), ")")
end
