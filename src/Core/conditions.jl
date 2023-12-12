"""
$(TYPEDEF)
$(TYPEDFIELDS)

Label of a Transition that determines when the transition fires.

# Examples

```jldoctest; setup=:(using PNML; using PNML: Condition)
julia> c = Condition(false)
Condition(nothing, Term(:bool, false), nothing, ToolInfo[])

julia> c()
false

julia> c = Condition("xx", false)
Condition("xx", Term(:bool, false), nothing, ToolInfo[])

julia> c()
false
```
"""
@auto_hash_equals struct Condition <: Annotation
    text::Maybe{String}
    value::Term #!{Bool}
    graphics::Maybe{Graphics}
    tools::Vector{ToolInfo}
end

Condition(value::Bool) = Condition(nothing, Term(:bool, value), nothing, ToolInfo[])
Condition(text::AbstractString, value::Bool) = Condition(text, Term(:bool, value), nothing, ToolInfo[])
Condition(value::Term) = Condition(nothing, value, nothing, ToolInfo[])
Condition(text::AbstractString, value::Term) = Condition(text, value, nothing, ToolInfo[])
condition_type(::Type{<:PnmlType}) = Condition

value(c::Condition) = c.value
Base.eltype(::Type{<:Condition}) = Bool # Output type of _evaluate
condition_value_type(::Type{<: PnmlType}) = Bool
condition_value_type(::Type{<: AbstractHLCore}) = eltype(BoolSort)

(c::Condition)() = _evaluate(value(c))::eltype(c)

function Base.show(io::IO, c::Condition)
    print(io, nameof(typeof(c)), "(")
    show(io, text(c)); print(io, ", ")
    show(io, value(c)); print(io, ", ")
    show(io, graphics(c)); print(io, ", ")
    show(io, tools(c));
    print(io, ")")
end

"""
$(TYPEDSIGNATURES)
Return default condition based on `PNTD`. Has meaning of true or always.
```
"""
function default_condition end
default_condition(x::Any) = (throw ∘ ArgumentError)("no default condition for $(typeof(x))")
default_condition(::PnmlType)              = Condition(true)
default_condition(::AbstractContinuousNet) = Condition(true)
default_condition(pntd::AbstractHLCore)    = Condition(default_bool_term(pntd))
