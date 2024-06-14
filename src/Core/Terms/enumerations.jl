#

"""
$(TYPEDEF)
See [`FiniteEnumerationSort`](@ref), [`CyclicEnumerationSort`](@ref).
Both hold an ordered collection of [`FEConstant`](@ref) accessable through
the `elements` iterator.
"""
abstract type EnumerationSort <: AbstractSort end

function Base.getproperty(sort::EnumerationSort, prop_name::Symbol)
    prop_name === :fec_refs && return getfield(sort, :fec_refs)::Vector{Symbol}
    prop_name === :ids && return getfield(sort, :ids)::Tuple
    return getfield(sort, prop_name)
end

netid(sort::EnumerationSort) = netid(sort.ids)
refs(sort::EnumerationSort) = sort.fec_refs

"""
    elements(sort::EnumerationSort) -> Iterator

Return iterator into feconstant(decldict(netid)) for this sort's `FEConstants`.
Maintains order of this sort.
"""
elements(sort::EnumerationSort) = Iterators.map(Fix1(feconstant, decldict(netid(sort))), refs(sort))


"Return number of `FEConstants` contained by this sort."
Base.length(sort::EnumerationSort) = length(refs(sort))

"""
$(TYPEDEF)

The operations differ between the various `EnumerationSort`s. They may be #TODO
"""
@auto_hash_equals fields=fec_refs struct CyclicEnumerationSort <: EnumerationSort
    fec_refs::Vector{Symbol} # keys into feconstant(decldict)
    ids::Tuple
end
#CyclicEnumerationSort(; ids::Tuple=(:emptyenumeration,)) = CyclicEnumerationSort(Symbol[]; ids)
CyclicEnumerationSort(fe_refs; ids::Tuple=(:emptyenumeration,)) = CyclicEnumerationSort(fe_refs, ids)

"""
$(TYPEDEF)
"""
@auto_hash_equals fields=fec_refs struct FiniteEnumerationSort <: EnumerationSort
    fec_refs::Vector{Symbol} # keys into feconstant(ddict)
    ids::Tuple
end
#FiniteEnumerationSort(; ids::Tuple=(:emptyenumeration,)) = FiniteEnumerationSort(Symbol[]; ids)
FiniteEnumerationSort(fe_refs; ids::Tuple=(:emptyenumeration,)) = FiniteEnumerationSort(fe_refs, ids)

function Base.show(io::IO, esort::EnumerationSort)
    print(io, nameof(typeof(esort)), "([")
    io = inc_indent(io)
    for  (i, fec) in enumerate(elements(esort))
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
    ids::Tuple # trail of IDs, first is netid.
end
#FiniteIntRangeSort() = FiniteIntRangeSort(0, 0, (:NOTHING,))
FiniteIntRangeSort(start, stop; ids::Tuple) = FiniteIntRangeSort(start, stop, ids)

Base.eltype(::FiniteIntRangeSort{T}) where {T} = T
start(fir::FiniteIntRangeSort) = fir.start
stop(fir::FiniteIntRangeSort) = fir.stop

"Return iterator from range start to range stop, inclusive"
elements(fir::FiniteIntRangeSort) = Iterators.map(identity, start(fir):stop(fir))

function Base.show(io::IO, fir::FiniteIntRangeSort)
    print(io, "FiniteIntRangeSort(", start(fir), ", ", stop(fir), ")")
end

"""
Must refer to a value between the start and end of the respective `FiniteIntRangeSort`.
"""
struct FiniteIntRangeConstant{T<:Integer} <: AbstractOperator
    value::T
    sort::FiniteIntRangeSort #! de-duplicate?
end
tag(::FiniteIntRangeConstant) = :finiteintrangeconstant
sortof(c::FiniteIntRangeConstant) = c.sort
value(c::FiniteIntRangeConstant) = c.value
_evaluate(c::FiniteIntRangeConstant) = value(c)
(c::FiniteIntRangeConstant)() = value(c)
