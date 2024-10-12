#

"""
$(TYPEDEF)
See [`FiniteEnumerationSort`](@ref), [`PNML.Sorts.CyclicEnumerationSort`](@ref).
Both hold an ordered collection of [`PNML.Declarations.FEConstant`](@ref) REFIDs and metadata.
"""
abstract type EnumerationSort{N,M} <: AbstractSort end

refs(sort::EnumerationSort) = sort.fec_refs

"""
    sortelements(sort::EnumerationSort) -> Iterator

Return iterator into feconstant(DECLDICT[]) for this sort's `FEConstants`.
Maintains order of this sort.
"""
sortelements(sort::EnumerationSort) = Iterators.map(Fix1(feconstant, PNML.DECLDICT[]), refs(sort))

"Return number of `FEConstants` contained by this sort."
Base.length(sort::EnumerationSort) = length(refs(sort))

Base.eltype(::EnumerationSort) = REFID

"""
$(TYPEDEF)

Wraps tuple of REFIDs into feconstant(decldict).
Operations differ between `EnumerationSort`s. All wrap a tuple of symbols and
metadata, allowing attachment of Partition/PartitionElement.
"""
@auto_hash_equals fields=fec_refs struct CyclicEnumerationSort{N, M} <: EnumerationSort{N,M}
    fec_refs::NTuple{N,REFID}  # ordered collection of FEConstant REFIDs
    metadata::M #! TermInfo metadata
end
function CyclicEnumerationSort(fecs)
    CyclicEnumerationSort(fecs, nothing)
end
tag(::CyclicEnumerationSort) = :cyclicenumeration # Used in metaprogramming?

"""
$(TYPEDEF)
Wraps tuple of IDREFs into feconstant(decldict).
"""
@auto_hash_equals fields=fec_refs struct FiniteEnumerationSort{N, M} <: EnumerationSort{N,M}
    fec_refs::NTuple{N,REFID} # ordered collection of FEConstant REFIDs
    metadata::M #! TermInfo metadata
end
function FiniteEnumerationSort(fe_refs)
    FiniteEnumerationSort(fe_refs, nothing)
end
tag(::FiniteEnumerationSort) = :finiteenumeration

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
    FiniteIntRangeSort(start::T, stop::T; meta) where {T<:Integer} -> Range
"""
@auto_hash_equals fields=start,stop struct FiniteIntRangeSort{T<:Integer, M} <: AbstractSort
    start::T
    stop::T # XML Schema calls this 'end'.
    meta::M #! TermInfo metadata
end
FiniteIntRangeSort(start, stop; meta=nothing) = FiniteIntRangeSort(start, stop, meta)

tag(::FiniteIntRangeSort) = :finiteintrange
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
    sort::UserSort # wrapping a FiniteIntRangeSort
end
tag(::FiniteIntRangeConstant) = :finiteintrangeconstant

#! FIR constants have an embedded sort definition, NOT a namedsort or usersort
sortref(c::FiniteIntRangeConstant) = error("sortref(c::FiniteIntRangeConstant) not defind!")
sortof(c::FiniteIntRangeConstant) = sortdefinition(c)
sortdefinition(c::FiniteIntRangeConstant) = c.sort

value(c::FiniteIntRangeConstant) = c.value
(c::FiniteIntRangeConstant)() = value(c)
toexpr(c::FiniteIntRangeConstant) = value(c)

#!_evaluate(c::FiniteIntRangeConstant) = begin println("_evaluate: FiniteIntRangeConstant"); value(c); end #! TODO term rewrite
