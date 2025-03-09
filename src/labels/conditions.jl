"""
$(TYPEDEF)
$(TYPEDFIELDS)

Label a Transition with an boolean expression used to determine when/if the transition fires.

There may be other things evaluating to boolean used to determine transition firing filters,
including: priority labels, inhibitor arc, place capacity labels, time/delay labels.

# Examples

```jldoctest; setup=:(using PNML; using PNML: BooleanEx, BooleanConstant)
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
@auto_hash_equals mutable struct Condition{T<:PnmlExpr, N} <: Annotation #TODO make LL & HL specializations?
    text::Maybe{String}
    term::T # duck-typed BoolExpr
    # color function: uses term and args, Built/JITed
    graphics::Maybe{Graphics} #TODO switch order of graphics, tools everywhere!
    tools::Maybe{Vector{ToolInfo}}
    vars::NTuple{N,REFID}
end

#! 2024-10-21 as part of transition to TermInterface change value to term,
Condition(b::Bool)            = Condition(BooleanConstant(b))
Condition(c::BooleanConstant) = Condition(PNML.BooleanEx(c))
Condition(expr::PNML.BooleanEx)    = Condition(nothing, expr, nothing, nothing, ())
Condition(text::AbstractString, b::Bool)            = Condition(text, BooleanConstant(b))
Condition(text::AbstractString, c::BooleanConstant) = Condition(text, PNML.BooleanEx(c))
Condition(text::AbstractString, expr::PNML.BooleanEx) = Condition(text, expr, nothing, nothing, ())

condition_type(::Type{<:PnmlType}) = Condition
Base.eltype(::Type{<:Condition}) = Bool

#! Term may be non-ground and need arguments:
#! pnml variable expressions that reference a marking's value?
# The expression is used to construct a "color function" whose arguments are variables.
# The Condition functor is the color function.
term(c::Condition) = c.term #todo! pnml variables

variables(c::Condition) = c.vars

#^+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
"""
    (c::Condition)(args) -> Bool

Use `args`, a dictionary of variable substitutions into the expression to return a Bool.
"""
(c::Condition)(varsub::NamedTuple=NamedTuple()) = begin
    # `varsub` a Dict mapping a variable REFID symbol to an element of the basis sort of marking multiset.
    # It will be a "consistent substitution"
    # Markings are ground terms, can be fully evaluated here. In fact, here we are operating
    # on a marking vector. This vector starts with the initial_marking expression's value.
    return cond_implementation(c, varsub)
end

# color function?
function cond_implementation(c::Condition, varsub::NamedTuple)
    for arg in keys(varsub)
        @show arg
    end
    # BooleanEx is a literal. BoolExpr <: PnmlExpr can be non-literal (non-ground term).
    isa(term(c), PNML.BooleanEx) || @warn term(c) varsub toexpr(term(c), varsub) #! debug

    eval(toexpr(term(c), varsub))::eltype(c) # Bool isa Number
end

condition_value_type(::Type{<: PnmlType}) = eltype(BoolSort)

function Base.show(io::IO, c::Condition)
    print(io, nameof(typeof(c)), "(")
    show(io, text(c)); print(io, ", ")
    show(io, term(c))
    print(io, ")")
end

"""
    default_condition(pntd::PnmlType) -> Condition

Has meaning of true or always.
"""
default_condition(::PnmlType) = Condition(PNML.BooleanEx(BooleanConstant(true)))
