"""
Number-valued label of [`Place`](@ref).
See [`PTNet`](@ref), [`ContinuousNet`](@ref).

Is a functor that returns the `value`.

$(TYPEDEF)
$(TYPEDFIELDS)

# Examples

```jldoctest; setup=:(using PNML: Marking)
julia> m = Marking()
Marking(0, )

julia> m()
0

julia> m = Marking(1)
Marking(1, )

julia> m()
1

julia> m = Marking(12.34)
Marking(12.34, )

julia> m()
12.34
```
"""
struct Marking{N<:Union{Int,Float64}} <: Annotation
    value::N
    com::ObjectCommon
    # Marking does not use ObjectCommon.graphics,
    # but rather, TokenGraphics in ObjectCommon.tools.
end
Marking() = Marking(zero(Int))
Marking(value::Union{Int,Float64}) = Marking(value, ObjectCommon())

value(m::Marking) = m.value
common(m::Marking) = m.com

"""
$(TYPEDSIGNATURES)
Evaluate a [`Marking`](@ref) instance by returning its value.
"""
(mark::Marking)() = _evaluate(value(mark))

"""
Use PNML type as trait to select type of marking.
"""
function markingtype end

"""
Use PNML type as trait to select valuetype of marking.
"""
function markingvaluetype end

markingtype(::PnmlType) = Marking
markingvaluetype(::PnmlType) = Int
markingvaluetype(::AbstractContinuousNet) = Float64
