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
    #@show s.fec_refs
    dd = decldict(netid(s))
    # Return an iterator into dd that maintains order.
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
CyclicEnumerationSort(netid::Symbol = :emptynet) = CyclicEnumerationSort(Symbol[], netid)

"""
$(TYPEDEF)
"""
@auto_hash_equals struct FiniteEnumerationSort <: EnumerationSort
    fec_refs::Vector{Symbol} # keys into feconstant(ddict)
    netid::Symbol
end
FiniteEnumerationSort(netid::Symbol = :emptynet) = FiniteEnumerationSort(Symbol[], netid)

function Base.show(io::IO, es::EnumerationSort)
    print(io, nameof(typeof(es)), "([")
    io = inc_indent(io)
    e = elements(es)
    for  (i, c) in enumerate(e)
        print(io, '\n', indent(io), c); #! show(io, c);
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
