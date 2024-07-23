"""
$(TYPEDEF)
$(TYPEDFIELDS)

Label of a Transition that determines when the transition fires.

# Examples

```jldoctest; setup=:(using PNML; using PNML: BooleanConstant)
julia> c = PNML.Labels.Condition(false)
Condition("", false)

julia> c()
false

julia> c = PNML.Labels.Condition("xx", false)
Condition("xx", false)

julia> c()
false
```
"""
@auto_hash_equals struct Condition <: Annotation #TODO make LL & HL like marking, inscription
    text::Maybe{String}
    value::AbstractTerm # term is expression that evaluates to Boolean.
    graphics::Maybe{Graphics}
    tools::Maybe{Vector{ToolInfo}}
end
# more reasons for the split: Number vs Term
Condition(value::Bool)                       = Condition(nothing, BooleanConstant(value), nothing, nothing)
Condition(value::BooleanConstant)            = Condition(nothing, value, nothing, nothing)
Condition(text::AbstractString, value::Bool) = Condition(text, BooleanConstant(value), nothing, nothing)
Condition(text::AbstractString, value::BooleanConstant) = Condition(text, value, nothing, nothing)

condition_type(::Type{<:PnmlType}) = Condition

value(c::Condition) = (c.value)() # Evaluate term
Base.eltype(::Type{<:Condition}) = Bool # Output type of _evaluate when iterating over transitions.
condition_value_type(::Type{<: PnmlType}) = eltype(BoolSort)
condition_value_type(::Type{<: AbstractHLCore}) = eltype(BoolSort)

(c::Condition)() = begin
    _evaluate(value(c))::eltype(c)
end

function Base.show(io::IO, c::Condition)
    print(io, nameof(typeof(c)), "(")
    show(io, text(c)); print(io, ", ")
    show(io, value(c))
    # if has_graphics(c)
    #     print(io, ", ")
    #     show(io, graphics(c))
    # end
    # if has_tools(c)
    #     print(io, ", ")
    #     show(io, tools(c));
    # end
    print(io, ")")
end

"""
$(TYPEDSIGNATURES)
Return default condition based on `PNTD`. Has meaning of true or always.
"""
function default_condition end
default_condition(::PnmlType)              = Condition(true)
default_condition(::AbstractContinuousNet) = Condition(true)
default_condition(pntd::AbstractHLCore)    = Condition(BooleanConstant(true))
