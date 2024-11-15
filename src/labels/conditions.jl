"""
$(TYPEDEF)
$(TYPEDFIELDS)

Label a Transition with an boolean expression used to determine when/if the transition fires.

There may be other things evaluating to boolean used to determine transition firing filters,
including: priority labels, inhibitor arc, place capacity labels, time/delay labels.

# Examples

```jldoctest; setup=:(using PNML; using PNML: BooleanConstant)
julia> c = PNML.Labels.Condition(false)
Condition("", BooleanEx(BooleanConstant(false)))

julia> c()
false

julia> c = PNML.Labels.Condition("xx", BooleanEx(BooleanConstant(true)))
Condition("xx", BooleanEx(BooleanConstant(true)))

julia> c()
true
```
"""
@auto_hash_equals struct Condition{T<:PnmlExpr} <: Annotation #TODO make LL & HL like marking, inscription
    text::Maybe{String}
    term::T #! has toexpr() BoolExpr
    graphics::Maybe{Graphics}
    tools::Maybe{Vector{ToolInfo}}
end
#! 2024-10-21 as part of transition to TermInterface change value to term a duck-typed BoolExpr
Condition(term::Bool)         = Condition(BooleanConstant(term))
Condition(c::BooleanConstant) = Condition(BooleanEx(c))
Condition(ex::BooleanEx)      = Condition(nothing, ex, nothing, nothing)
Condition(text::AbstractString, term::Bool)         = Condition(text, BooleanConstant(term))
Condition(text::AbstractString, c::BooleanConstant) = Condition(text, BooleanEx(c))
Condition(text::AbstractString, ex::BooleanEx)      = Condition(text, ex, nothing, nothing)

condition_type(::Type{<:PnmlType}) = Condition
Base.eltype(::Type{<:Condition}) = Bool

#! Term may be non-ground and need arguments:
#! pnml variable expressions that reference a marking's value?
term(c::Condition) = c.term #todo! pnml variables
(c::Condition)() = eval(toexpr(term(c)))::eltype(c) # Bool isa Number #todo! pnml variables

condition_value_type(::Type{<: PnmlType}) = eltype(BoolSort)
condition_value_type(::Type{<: AbstractHLCore}) = eltype(BoolSort)

function Base.show(io::IO, c::Condition)
    print(io, nameof(typeof(c)), "(")
    show(io, text(c)); print(io, ", ")
    show(io, term(c))
    print(io, ")")
end

"""
$(TYPEDSIGNATURES)
Return default condition based on `PNTD`. Has meaning of true or always.
"""
function default_condition end
default_condition(::PnmlType) = Condition(BooleanEx(BooleanConstant(true)))
