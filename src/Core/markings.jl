# PNML (the ISO Specification) defines separate XML marking syntax variants for
# Place/Transition Nets (plain) and High-level (many-sorted).
# TODO Add variant for tuples? Enumerations? (-1, 0 , 1) et al. to avoid HL mechansim?
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Number-valued label of [`Place`](@ref).
See [`PTNet`](@ref), [`ContinuousNet`](@ref), [`HLMarking`](@ref).

Is a functor that returns the `value`.

# Examples

```jldoctest; setup=:(using PNML: Marking)
julia> m = Marking(1)
Marking(1)

julia> m()
1

julia> m = Marking(12.34)
Marking(12.34)

julia> m()
12.34
```
"""
struct Marking{N <: Number} <: Annotation
    value::N
    graphics::Maybe{Graphics} # PTNet uses TokenGraphics in tools rather than graphics.
    tools::Maybe{Vector{ToolInfo}}
end
# Allow any Number subtype, expect a few concrete subtypes without comment.
Marking(value::Union{Int,Float64}) = Marking(value, nothing, nothing)
Marking(value::Number) = begin # Comment on unexpected type.
    @warn lazy"marking value unexpected type $(typeof(value))"
    Marking(value, nothing, nothing)
end


# We give NHL (non-High-Level) nets a sort interface by mapping from type to sort.
# Extending to allow non-integer makes this #! INTERESTING and HACKEY!
# Note that Integer also extends the specification by allowing negative numbers.
# A marking is a multiset of elements of the sort.
# In the NHL we want (require) that:
"""
    value(m::Marking) -> Number
"""
value(marking::Marking) = marking.value
# 1'value where value isa eltype(sortof(marking))
# because we assume a multiplicity of 1, and the sort is simple
#TODO add sort trait where simple means has concrete eltype
# Assume eltype(sortof(marking)) == typeof(value(marking))
sortof(m::Marking) = isa(m.value, Integer) ? IntegerSort() : RealSort() # ! TODO cleanup

"""
$(TYPEDSIGNATURES)
Evaluate [`Marking`](@ref) instance by returning its evaluated value.
"""
(mark::Marking)() = _evaluate(value(mark))

function Base.show(io::IO, ptm::Marking)
    print(io, indent(io), "Marking(")
    show(io, value(ptm))
    if has_graphics(ptm)
        print(io, ", ")
        show(io, graphics(ptm))
    end
    if has_tools(ptm)
        print(io, ", ")
        show(io, tools(ptm));
    end
    print(io, ")")
end

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Multiset of a sort labelling of a `Place` in a High-level Petri Net Graph.
See [`AbstractHLCore`](@ref), [`AbstractTerm`](@ref), [`Marking`](@ref).

Is a functor that returns the evaluated `value`.

# Examples

```jldoctest; setup=:(using PNML; using PNML: HLMarking, NaturalSort, NumberConstant)
julia> m = HLMarking("the text", NumberConstant(3, NaturalSort()))
HLMarking("the text", NumberConstant{Int64, NaturalSort}(3, NaturalSort()))

julia> m()
3
```
"""
struct HLMarking <: HLAnnotation
    text::Maybe{String} # Supposed to be for human consumption.
    term::AbstractTerm # Content of <structure> must be a many-sorted algebra term.
    graphics::Maybe{Graphics}
    tools::Maybe{Vector{ToolInfo}}
end

HLMarking(t::AbstractTerm) = HLMarking(nothing, t)
HLMarking(s::Maybe{AbstractString}, t::Maybe{AbstractTerm}) = HLMarking(s, t, nothing, nothing)

value(m::HLMarking) = m.term
sortof(m::HLMarking) = sortof(m.term) #TODO sorts

function Base.show(io::IO, hlm::HLMarking)
    print(io, indent(io), "HLMarking(")
    show(io, text(hlm)); print(io, ", ")
    show(io, value(hlm)) # Term
    if has_graphics(hlm)
        print(io, ", ")
        show(io, graphics(hlm))
    end
    if has_tools(hlm)
        print(io, ", ")
        show(io, tools(hlm));
    end
    print(io, ")")
end

"""
$(TYPEDSIGNATURES)
Evaluate a [`HLMarking`](@ref) instance by returning its term.
"""
(hlm::HLMarking)() = _evaluate(value(hlm))
#TODO convert to sort
#TODO query sort

marking_type(::Type{T}) where {T <: PnmlType} = Marking{marking_value_type(T)}
marking_type(::Type{T}) where {T<:AbstractHLCore} = HLMarking

marking_value_type(::Type{<:PnmlType}) = Int
marking_value_type(::Type{<:AbstractHLCore}) = eltype(DotSort())
marking_value_type(::Type{<:AbstractContinuousNet}) = Float64

"""
$(TYPEDSIGNATURES)
Return default marking value based on `PNTD`. Has meaning of empty, as in `zero`.
"""
function default_marking end
default_marking(x::Any) = (throw ∘ ArgumentError)("no default marking for $(typeof(x))")
default_marking(::PnmlType)              = Marking(zero(Int))
default_marking(::AbstractContinuousNet) = Marking(zero(Float64))
default_marking(pntd::AbstractHLCore)    = HLMarking(default_zero_term(pntd))
