#

"""
$(TYPEDEF)
"""
abstract type EnumerationSort <: AbstractSort end

function Base.getproperty(s::EnumerationSort, prop_name::Symbol)
    prop_name === :elements && return getfield(s, :elements)::Vector{FEConstant}
    return getfield(o, prop_name)
end

elements(s::EnumerationSort) = s.elements

"""
$(TYPEDEF)

The operations differ between the various `EnumerationSort`s. They may be #TODO
"""
@auto_hash_equals struct CyclicEnumerationSort <: EnumerationSort
    elements::Vector{FEConstant}
end
CyclicEnumerationSort() = CyclicEnumerationSort(FEConstant[])

"""
$(TYPEDEF)
"""
@auto_hash_equals struct FiniteEnumerationSort <: EnumerationSort
    elements::Vector{FEConstant}
end
FiniteEnumerationSort() = FiniteEnumerationSort(FEConstant[])

function Base.show(io::IO, es::EnumerationSort)
    print(io, nameof(typeof(es)), "([")
    io = inc_indent(io)
    for  (i, c) in enumerate(elements(es))
        print(io, '\n', indent(io)); show(io, values(c));
        i < length(elements(es)) && print(io, ",")
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
