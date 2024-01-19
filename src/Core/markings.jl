"""
$(TYPEDEF)
$(TYPEDFIELDS)

Number-valued label of [`Place`](@ref).
See [`PTNet`](@ref), [`ContinuousNet`](@ref), [`HLMarking`](@ref).

Is a functor that returns the `value`.

# Examples

```jldoctest; setup=:(using PNML: Marking)
julia> m = Marking(1)
Marking(1, nothing, [])

julia> m()
1

julia> m = Marking(12.34)
Marking(12.34, nothing, [])

julia> m()
12.34
```
"""
struct Marking{N<:Union{Int,Float64}} <: Annotation
    value::N
    graphics::Maybe{Graphics} # PTNet uses TokenGraphics in tools rather than graphics.
    tools::Vector{ToolInfo}
end

Marking(value::Union{Int,Float64}) = Marking(value, nothing, ToolInfo[])

"""
    value(m::Marking) -> Union{Int,Float64}
"""
value(m::Marking) = m.value

"""
$(TYPEDSIGNATURES)
Evaluate [`Marking`](@ref) instance by returning its evaluated value.
"""
(mark::Marking)() = _evaluate(value(mark))


function Base.show(io::IO, ptm::Marking)
    pprint(io, ptm)
end

PrettyPrinting.quoteof(m::Marking) = :(Marking($(PrettyPrinting.quoteof(value(m))),
        $(PrettyPrinting.quoteof(m.graphics)),
        $(PrettyPrinting.quoteof(m.tools))))

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Multiset of a sort labelling of a `Place` in a High-level Petri Net Graph.
See [`AbstractHLCore`](@ref), [`Term`](@ref), [`Marking`](@ref).

Is a functor that returns the evaluated `value`.

# Examples

```jldoctest; setup=:(using PNML; using PNML: HLMarking, Term)
julia> m = HLMarking("the text", Term(:value, 3))
HLMarking("the text", Term(:value, 3), nothing, [])

julia> m()
3
```
"""
struct HLMarking{T <: AbstractTerm} <: HLAnnotation
    text::Maybe{String} # Supposed to be for human consumption.
    term::T # Content of <structure> must be a many-sorted algebra term.
    graphics::Maybe{Graphics}
    tools::Vector{ToolInfo}
end

HLMarking(t::AbstractTerm)   = HLMarking(nothing, t)
HLMarking(s::Maybe{AbstractString}, t::Maybe{AbstractTerm}) = HLMarking(s, t, nothing, ToolInfo[])

value(m::HLMarking) = m.term

function Base.summary(hlm::HLMarking)
    string(typeof(hlm))
end

function Base.show(io::IO, hlm::HLMarking)
    pprint(io, hlm)
end

quoteof(m::HLMarking) = :(HLMarking($(quoteof(text(m))), $(quoteof(value(m))),
                                    $(quoteof(graphics(m))), $(quoteof(tools(m)))))


#! HLMarking is a multiset, not an expression.
"""
$(TYPEDSIGNATURES)
Evaluate a [`HLMarking`](@ref) instance by returning its term.
"""
(hlm::HLMarking)() = _evaluate(value(hlm))
#TODO convert to sort
#TODO query sort

marking_type(::Type{T}) where {T <: PnmlType} = Marking{marking_value_type(T)}
marking_type(::Type{T}) where {T<:AbstractHLCore} = HLMarking{Term}

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
