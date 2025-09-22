#

"""
$(TYPEDEF)
See [`FiniteEnumerationSort`](@ref), [`PNML.Sorts.CyclicEnumerationSort`](@ref).
Both hold an ordered collection of [`PNML.FEConstant`](@ref) REFIDs and metadata.
"""
abstract type EnumerationSort{M} <: AbstractSort end

"""
    refs(sort::EnumerationSort) -> Vector{REFID}

Return `Vector` of `FEConstant` `REFID`s.
"""
refs(sort::EnumerationSort) = sort.fec_refs # NTuple

"""
    sortelements(sort::EnumerationSort) -> Iterator

Return iterator into feconstant(decldict) for this sort's `FEConstants`.
Maintains order of this sort.
"""
sortelements(sort::EnumerationSort) = refs(sort)

"Return number of `FEConstants` contained by this sort."
Base.length(sort::EnumerationSort) = length(refs(sort))

Base.eltype(::EnumerationSort) = REFID

function Base.show(io::IO, esort::EnumerationSort)
    print(io, nameof(typeof(esort)), "([")
    io = PNML.inc_indent(io)
    for (i, fec_ref) in enumerate(refs(esort))
        print(io, '\n', PNML.indent(io), fec_ref);
        i < length(esort) && print(io, ",")
    end
    print(io, "])")
end

"""
$(TYPEDEF)

Wraps tuple of REFIDs into feconstant(decldict).

Operations differ between `EnumerationSort`s. All wrap a tuple of symbols and
metadata, allowing attachment of Partition/PartitionElement.

See ISO/IEC 15909-2:2011/Cor.1:2013(E) defect 11 power or nth successor/predecessor

MCC2023/SharedMemory-COL-100000 has cyclic enumeration with 100000 <feconstant> elements.
"""
@auto_hash_equals fields=fec_refs typearg=true struct CyclicEnumerationSort{M} <: EnumerationSort{M}
    # Difference of Cyclic from Finite EnumerationSort is successor/predecessor operators.
    fec_refs::Vector{REFID} # ordered collection of FEConstant REFIDs
    metadata::M # TODO TermInterface metadata
    declarationdicts::DeclDict
end

tag(::CyclicEnumerationSort) = :cyclicenumeration # XML <tag>

#TODO successor/predecessor methods

"""
    FiniteEnumerationSort(ntuple) -> FiniteEnumerationSort{M}
Wraps a collection of `FEConstant` REFIDs. Usage: `feconstant(decldict)[refid]`.
"""
@auto_hash_equals fields=fec_refs typearg=true struct FiniteEnumerationSort{M} <: EnumerationSort{M}
    fec_refs::Vector{REFID} # ordered collection of FEConstant REFIDs
    #TODO! Constructor version with start,end attributes. See ISO/IEC 15909-2:2011/Cor.1:2013(E) defect 10
    metadata::M # TODO TermInterface metadata
    declarationdicts::DeclDict
end

tag(::FiniteEnumerationSort) = :finiteenumeration

"""
    $(TYPEDEF)
    FiniteIntRangeSort(start::T, stop::T) where {T<:Integer}
"""
@auto_hash_equals fields=start,stop typearg=true struct FiniteIntRangeSort{T<:Integer} <: AbstractSort
    start::T
    stop::T # XML Schema calls this 'end'.
    declarationdicts::DeclDict
end

tag(::FiniteIntRangeSort) = :finiteintrange
Base.eltype(::FiniteIntRangeSort{T}) where {T<:Integer} = T
start(fir::FiniteIntRangeSort) = fir.start
stop(fir::FiniteIntRangeSort) = fir.stop

"""
    $(TYPEDEF)
Return iterator from `start` to `stop`, inclusive.
"""
sortelements(fir::FiniteIntRangeSort) = Iterators.map(identity, start(fir):stop(fir))

function Base.show(io::IO, fir::FiniteIntRangeSort)
    print(io, "FiniteIntRangeSort(", start(fir), ", ", stop(fir), ")")
end
