"""
$(TYPEDEF)
$(TYPEDFIELDS)

Label a Transition with an boolean expression used to determine when/if the transition fires.

There may be other things evaluating to boolean used to determine transition firing filters,
including: priority labels, inhibitor arc, place capacity labels, time/delay labels.

# Examples

```jldoctest; setup=:(using PNML; using PNML: BooleanConstant)
julia> c = PNML.Labels.Condition(false)
Condition("", false)

julia> c()
false

julia> c = PNML.Labels.Condition("xx", true)
Condition("xx", true)

julia> c()
true
```
"""
@auto_hash_equals struct Condition <: Annotation #TODO make LL & HL like marking, inscription
    text::Maybe{String}
    term::Any #! has toexpr() BoolExpr
    graphics::Maybe{Graphics}
    tools::Maybe{Vector{ToolInfo}}
end
#! 2024-10-21 as part of transition to TermInterface change value to term a duck-typed BoolExpr
Condition(term) = Condition(nothing, term, nothing, nothing)
Condition(text::AbstractString, term) = Condition(text, term, nothing, nothing)

condition_type(::Type{<:PnmlType}) = Condition
Base.eltype(::Type{<:Condition}) = Bool

#! Term may be non-ground and need arguments:
#! pnml variable expressions that reference a marking's value?
value(c::Condition) = toexpr(c.term) #todo! pnml variables
(c::Condition)() = value(c)::eltype(c) # Bool isa Number #todo! pnml variables

condition_value_type(::Type{<: PnmlType}) = eltype(BoolSort)
condition_value_type(::Type{<: AbstractHLCore}) = eltype(BoolSort)

function Base.show(io::IO, c::Condition)
    print(io, nameof(typeof(c)), "(")
    show(io, text(c)); print(io, ", ")
    show(io, value(c))
    print(io, ")")
end

"""
$(TYPEDSIGNATURES)
Return default condition based on `PNTD`. Has meaning of true or always.
"""
function default_condition end
default_condition(::PnmlType)              = Condition(BooleanConstant(true))
