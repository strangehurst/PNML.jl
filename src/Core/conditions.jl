"""
$(TYPEDEF)
$(TYPEDFIELDS)

Label of a Transition that determines when the transition fires.

# Examples

```jldoctest; setup=:(using PNML; using PNML: Condition)
julia> c = Condition(false)
Condition("", Term(:bool, false))

julia> c()
false

julia> c = Condition("xx", false)
Condition("xx", Term(:bool, false))

julia> c()
false
```
"""
@auto_hash_equals struct Condition <: Annotation
    text::Maybe{String}
    value::Term #! expression evaluates to Bool
    graphics::Maybe{Graphics}
    tools::Maybe{Vector{ToolInfo}}
end

Condition(value::Bool)                       = Condition(nothing, Term(:bool, value), nothing, nothing)
Condition(value::Term)                       = Condition(nothing, value, nothing, nothing)
Condition(text::AbstractString, value::Bool) = Condition(text, Term(:bool, value), nothing, nothing)
Condition(text::AbstractString, value::Term) = Condition(text, value, nothing, nothing)
condition_type(::Type{<:PnmlType}) = Condition

value(c::Condition) = c.value
Base.eltype(::Type{<:Condition}) = Bool # Output type of _evaluate when iterating over transitions.
condition_value_type(::Type{<: PnmlType}) = Bool
condition_value_type(::Type{<: AbstractHLCore}) = eltype(BoolSort) #todo test that this is also Bool

(c::Condition)() = _evaluate(value(c))::eltype(c)

function Base.show(io::IO, c::Condition)
    print(io, nameof(typeof(c)), "(")
    show(io, text(c)); print(io, ", ")
    show(io, value(c))
    if has_graphics(c)
        print(io, ", ")
        show(io, graphics(c))
    end
    if has_tools(c)
        print(io, ", ")
        show(io, tools(c));
    end
    print(io, ")")
end

"""
$(TYPEDSIGNATURES)
Return default condition based on `PNTD`. Has meaning of true or always.
"""
function default_condition end
default_condition(x::Any) = (throw ∘ ArgumentError)("no default condition for $(typeof(x))")
default_condition(::PnmlType)              = Condition(true)
default_condition(::AbstractContinuousNet) = Condition(true)
default_condition(pntd::AbstractHLCore)    = Condition(default_bool_term(pntd))
