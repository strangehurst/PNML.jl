"""
$(TYPEDEF)
$(TYPEDFIELDS)

Label a Transition with an boolean expression used to determine when/if the transition fires.

There may be other things evaluating to boolean used to determine transition firing filters,
including: priority labels, inhibitor arc, place capacity labels, time/delay labels.

# Examples
Vector
```jldoctest; setup=:(using PNML; using PNML:  Labels, BooleanEx, BooleanConstant; using PNML.PnmlIDRegistrys; ctx=PNML.parser_context())
julia> c = Labels.Condition(false, ctx.ddict)
Condition("", BooleanEx(BooleanConstant(false)))

julia> c()
false

julia> c = Labels.Condition("xx", BooleanEx(BooleanConstant(true, ctx.ddict)), ctx.ddict)
Condition("xx", BooleanEx(BooleanConstant(true)))

julia> c()
true
```
"""
@auto_hash_equals fields=text,term,graphics,toolspecinfos,vars typearg=true struct Condition{T<:PnmlExpr} <: HLAnnotation
    text::Maybe{String}
    term::T # duck-typed BoolExpr
    # color function: uses term and args, Built/JITed
    graphics::Maybe{Graphics} #TODO switch order of graphics, toolinfos everywhere!
    toolspecinfos::Maybe{Vector{ToolInfo}}
    vars::Vector{REFID} #! XXX DOCUMENT ME XXX
    declarationdicts::DeclDict
end

Condition(b::Bool, ddict) = Condition(PNML.BooleanConstant(b, ddict), ddict)
Condition(c::PNML.BooleanConstant, ddict) = Condition(PNML.BooleanEx(c), ddict)
Condition(expr::PNML.BooleanEx, ddict) = Condition(nothing, expr, nothing, nothing, REFID[], ddict)
Condition(text::AbstractString, b::Bool, ddict) = Condition(text, PNML.BooleanConstant(b, ddict), ddict)
Condition(text::AbstractString, c::PNML.BooleanConstant, ddict) = Condition(text, PNML.BooleanEx(c), ddict)
Condition(text::AbstractString, expr::PNML.BooleanEx, ddict) = Condition(text, expr, nothing, nothing, REFID[], ddict)

Base.eltype(::Type{<:Condition}) = Bool
PNML.value_type(::Type{<:Condition}, ::PnmlType) = eltype(BoolSort)

decldict(c::Condition) = c.declarationdicts

#! Term may be non-ground and need arguments:
#! pnml variable expressions that reference a marking's value?
# The expression is used to construct a "color function" whose arguments are variables.
# The Condition functor is the color function.
term(c::Condition) = c.term #todo! pnml variables

variables(c::Condition) = c.vars

function default(::Type{<:Condition}, ::PnmlType; ddict::DeclDict)
    Condition(PNML.BooleanEx(PNML.BooleanConstant(true, ddict)), ddict)
end

"""
    (c::Condition)(args) -> Bool

Use `args`, a dictionary of variable substitutions into the expression to return a Bool.
"""
(c::Condition)(varsub::NamedTuple=NamedTuple()) = begin
    # `varsub` maps a variable REFID symbol to an element of the basis sort of marking multiset.
    # It will be a "consistent substitution"
    # Markings are ground terms, can be fully evaluated here. In fact, here we are operating
    # on a marking vector. This vector starts with the initial_marking expression's value.
    return cond_implementation(c, varsub)
end

# color function?
function cond_implementation(c::Condition, varsub::NamedTuple)
    # for arg in keys(varsub)
    #     @show arg
    # end
    # BooleanEx is a literal. BoolExpr <: PnmlExpr can be non-literal (non-ground term).
    isa(term(c), PNML.BooleanEx) || @warn term(c) varsub  #! debug
    #@show term(c) varsub toexpr(term(c), varsub, decldict(c))
    eval(toexpr(term(c), varsub, decldict(c)))::eltype(c) # Bool isa Number
end


function Base.show(io::IO, c::Condition)
    print(io, nameof(typeof(c)), "(")
    show(io, text(c)); print(io, ", ")
    show(io, term(c))
    print(io, ")")
end
