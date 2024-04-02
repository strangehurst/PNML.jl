#

"""
$(TYPEDEF)
"""
abstract type EnumerationSort <: AbstractSort end

function Base.getproperty(s::EnumerationSort, prop_name::Symbol)
    prop_name === :fec_refs && return getfield(s, :fec_refs)::Vector{Symbol}
    prop_name === :netid && return getfield(s, :netid)::Symbol
    return getfield(o, prop_name)
end
netid(s::EnumerationSort) = s.netid

"Return iterator into feconstant(decldict(netid)). Maintains order of this sort."
elements(s::EnumerationSort) = begin
    dd = decldict(netid(s))
    @show s.fec_refs typeof(dd.feconstants)
    # return an iterator that maintains the order of fec_refs.
    Iterators.map(ref->dd.feconstants[ref], s.fec_refs)
end

"""
$(TYPEDEF)

The operations differ between the various `EnumerationSort`s. They may be #TODO
"""
@auto_hash_equals struct CyclicEnumerationSort <: EnumerationSort
    fec_refs::Vector{Symbol} # keys into feconstant(decldict)
    netid::Symbol
end
CyclicEnumerationSort() = CyclicEnumerationSort(FEConstant[], :empty)

"""
$(TYPEDEF)
"""
@auto_hash_equals struct FiniteEnumerationSort <: EnumerationSort
    fec_refs::Vector{Symbol} # keys into feconstant(ddict)
    netid::Symbol
end
FiniteEnumerationSort() = FiniteEnumerationSort(FEConstant[], :empty)

function Base.show(io::IO, es::EnumerationSort)
    print(io, nameof(typeof(es)), "([")
    io = inc_indent(io)
    e = elements(es)
    for  (i, c) in enumerate(e)
        print(io, '\n', indent(io)); show(io, c);
        i < length(e) && print(io, ",")
    end
    print(io, "])")
end

"""
$(TYPEDEF)
"""
@auto_hash_equals struct FiniteIntRangeSort{T} <: AbstractSort
    start::T
    stop::T # XML Schema calls this 'end'.
end
FiniteIntRangeSort() = FiniteIntRangeSort(0, 0)
#! equalSorts(a::FiniteIntRangeSort, b::FiniteIntRangeSort) = (a.start == b.start && a.stop == b.stop)
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
