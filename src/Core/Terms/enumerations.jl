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
$(TYPEDEF)
"""
@auto_hash_equals struct FiniteIntRangeSort{T} <: AbstractSort
    start::T
    stop::T # XML Schema calls this 'end'.
    netid::Symbol
end
FiniteIntRangeSort(netid::Symbol = :emptynet) = FiniteIntRangeSort(0, 0, netid)
Base.eltype(::FiniteIntRangeSort{T}) where {T} = T

function Base.show(io::IO, s::FiniteIntRangeSort)
    print(io, "FiniteIntRangeSort(", s.start, ", ", s.stop, ")")
end



struct FiniteIntRangeConstant <: AbstractOperator
    value::String
    sort::FiniteIntRangeSort
end
tag(::FiniteIntRangeConstant) = :finiteintrangeconstant
sortof(::FiniteIntRangeConstant) = FiniteIntRangeSort
value(c::FiniteIntRangeConstant) = _evaluate(c)
_evaluate(c::FiniteIntRangeConstant) = c.value # TODO string
(c::FiniteIntRangeConstant)() = value(c)
