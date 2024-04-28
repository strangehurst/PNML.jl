#

"""
$(TYPEDEF)
"""
abstract type EnumerationSort <: AbstractSort end

function Base.getproperty(sort::EnumerationSort, prop_name::Symbol)
    prop_name === :fec_refs && return getfield(sort, :fec_refs)::Vector{Symbol}
    prop_name === :netid && return getfield(sort, :netid)::Symbol
    return getfield(sort, prop_name)
end

netid(sort::EnumerationSort) = sort.netid

"Return iterator into feconstant(decldict(netid)) for this sort's `FEConstants`. Maintains order of this sort."
elements(sort::EnumerationSort) = begin
    dd = decldict(netid(sort))
    Iterators.map(ref->dd.feconstants[ref], sort.fec_refs)
end

"Return number of `FEConstants` contained by this sort."
Base.length(sort::EnumerationSort) = length(sort.fec_refs)

"""
$(TYPEDEF)

The operations differ between the various `EnumerationSort`s. They may be #TODO
"""
@auto_hash_equals struct CyclicEnumerationSort <: EnumerationSort
    fec_refs::Vector{Symbol} # keys into feconstant(decldict)
    netid::Symbol
end
CyclicEnumerationSort(netid::Symbol = :emptynet) = CyclicEnumerationSort(Symbol[], netid)

"""
$(TYPEDEF)
"""
@auto_hash_equals struct FiniteEnumerationSort <: EnumerationSort
    fec_refs::Vector{Symbol} # keys into feconstant(ddict)
    netid::Symbol
end
FiniteEnumerationSort(netid::Symbol = :emptynet) = FiniteEnumerationSort(Symbol[], netid)

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
@auto_hash_equals struct FiniteIntRangeSort{T<:Integer} <: AbstractSort
    start::T
    stop::T # XML Schema calls this 'end'.
    ids::Tuple # trail of IDs, first is netid.
end
FiniteIntRangeSort() = FiniteIntRangeSort(0, 0, (:NOTHING,))
FiniteIntRangeSort(start, stop; ids::Tuple) = FiniteIntRangeSort(start, stop, ids)
Base.eltype(::FiniteIntRangeSort{T}) where {T} = T
start(fir::FiniteIntRangeSort) = fir.start
stop(fir::FiniteIntRangeSort) = fir.stop

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
