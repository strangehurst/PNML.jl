"""
Number-valued label of [`Place`](@ref).
See [`PTNet`](@ref), [`ContinuousNet`](@ref).

Is a functor that returns the `value`.

$(TYPEDEF)
$(TYPEDFIELDS)

# Examples

```jldoctest; setup=:(using PNML: PTMarking)
julia> m = PTMarking()
PTMarking(0, )

julia> m()
0

julia> m = PTMarking(1)
PTMarking(1, )

julia> m()
1

julia> m = PTMarking(12.34)
PTMarking(12.34, )

julia> m()
12.34
```
"""
struct PTMarking{N<:Union{Int,Float64}} <: Annotation
    value::N
    com::ObjectCommon
    # PTMarking does not use ObjectCommon.graphics,
    # but rather, TokenGraphics in ObjectCommon.tools.
end
PTMarking() = PTMarking(zero(Int))
PTMarking(value::Union{Int,Float64}) = PTMarking(value, ObjectCommon())

"""
$(TYPEDSIGNATURES)
Evaluate a [`PTMarking`](@ref) instance by returning its value.
"""
(mark::PTMarking)() = _evaluate(mark.value)
