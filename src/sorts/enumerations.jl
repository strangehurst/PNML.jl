#

"""
$(TYPEDEF)
See [`FiniteEnumerationSort`](@ref), [`PNML.Sorts.CyclicEnumerationSort`](@ref).
Both hold an ordered collection of [`PNML.Declarations.FEConstant`](@ref) accessable through
the `elements` iterator.
"""
abstract type EnumerationSort <: AbstractSort end

function Base.getproperty(sort::EnumerationSort, prop_name::Symbol)
    prop_name === :fec_refs && return getfield(sort, :fec_refs)::NTuple{<:Any, <:Symbol}
    #prop_name === :ids && return getfield(sort, :ids)::Tuple
    return getfield(sort, prop_name)
end

netid(sort::EnumerationSort) = netid(sort.ids)
refs(sort::EnumerationSort) = sort.fec_refs

"""
    sortelements(sort::EnumerationSort) -> Iterator

Return iterator into feconstant(DECLDICT[]) for this sort's `FEConstants`.
Maintains order of this sort.
"""
sortelements(sort::EnumerationSort) = Iterators.map(Fix1(feconstant, PNML.DECLDICT[]), refs(sort))


"Return number of `FEConstants` contained by this sort."
Base.length(sort::EnumerationSort) = length(refs(sort))

"""
$(TYPEDEF)

Wraps tuple of IDREFs into feconstant(decldict).
Operations differ between `EnumerationSort`s. All wrap a tuple of symbols.
metadata, allowing attachment of Partition/PartitionElement and id trail

"""
@auto_hash_equals fields=fec_refs struct CyclicEnumerationSort{T<:NTuple{<:Any, <:Symbol}, M} <: EnumerationSort
    fec_refs::T
    ids::M  #! Trail?
end
CyclicEnumerationSort(fe_refs; ids::Tuple=(:emptyenumeration,)) = CyclicEnumerationSort(fe_refs, ids)

# struct X{T<:NTuple{<:Any, <:Symbol}, M<:Any}
#     fec_refs::T
#     ids::M #^ metadata #! Trail
# end

"""
$(TYPEDEF)
Wraps tuple of IDREFs into feconstant(decldict).
"""
@auto_hash_equals fields=fec_refs struct FiniteEnumerationSort{T<:NTuple{<:Any, <:Symbol}, M} <: EnumerationSort
    fec_refs::T
    ids::M #^ metadata #! Trail
end
FiniteEnumerationSort(fe_refs; ids::Tuple=(:emptyenumeration,)) = FiniteEnumerationSort(fe_refs, ids)

# MCC2023/SharedMemory-COL-100000 has cyclic enumeration with 100000 <feconstant>

function Base.show(io::IO, esort::EnumerationSort)
    print(io, nameof(typeof(esort)), "([")
    io = inc_indent(io)
    for  (i, fec) in enumerate(sortelements(esort))
        print(io, '\n', indent(io), fec);
        i < length(esort) && print(io, ",")
    end
    print(io, "])")
end

"""
    FiniteIntRangeSort(start::T, stop::T; ids::Tuple) where {T<:Integer} -> Range
"""
@auto_hash_equals fields=start,stop struct FiniteIntRangeSort{T<:Integer} <: AbstractSort
    start::T
    stop::T # XML Schema calls this 'end'.
    ids::Tuple #! Trail of IDs, first is netid.
end
#FiniteIntRangeSort() = FiniteIntRangeSort(0, 0, (:NOTHING,))
FiniteIntRangeSort(start, stop; ids::Tuple) = FiniteIntRangeSort(start, stop, ids)

Base.eltype(::FiniteIntRangeSort{T}) where {T} = T
start(fir::FiniteIntRangeSort) = fir.start
stop(fir::FiniteIntRangeSort) = fir.stop

"Return iterator from range start to range stop, inclusive"
sortelements(fir::FiniteIntRangeSort) = Iterators.map(identity, start(fir):stop(fir))

function Base.show(io::IO, fir::FiniteIntRangeSort)
    print(io, "FiniteIntRangeSort(", start(fir), ", ", stop(fir), ")")
end

"""
Must refer to a value between the start and end of the respective `FiniteIntRangeSort`.
"""
struct FiniteIntRangeConstant{T<:Integer} # Duck-type  <: AbstractOperator
    value::T
    sort::FiniteIntRangeSort #! de-duplicate?
end
tag(::FiniteIntRangeConstant) = :finiteintrangeconstant
sortof(c::FiniteIntRangeConstant) = c.sort
value(c::FiniteIntRangeConstant) = c.value
_evaluate(c::FiniteIntRangeConstant) = value(c)
(c::FiniteIntRangeConstant)() = value(c)
