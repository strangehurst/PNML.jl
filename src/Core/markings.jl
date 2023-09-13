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

marking_type(::Type{T}) where {T <: PnmlType} = Marking{marking_value_type(T)}

marking_value_type(::Type{<:PnmlType}) = Int
marking_value_type(::Type{<:AbstractContinuousNet}) = Float64
