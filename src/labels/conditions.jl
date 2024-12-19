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
Condition(c::BooleanConstant) = Condition(BooleanEx(c))
Condition(expr::BooleanEx)    = Condition(nothing, expr, nothing, nothing, ())
Condition(text::AbstractString, b::Bool)            = Condition(text, BooleanConstant(b))
Condition(text::AbstractString, c::BooleanConstant) = Condition(text, BooleanEx(c))
Condition(text::AbstractString, expr::BooleanEx)    = Condition(text, expr, nothing, nothing, ())

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
(c::Condition)(sub::SubstitutionDict=SubstitutionDict()) = begin
    # `sub` a Dict mapping a variable REFID symbol to an element of the basis sort of marking multiset.
    # It will be a "consistent substitution"
    # Markings are ground terms, can be fully evaluated here. In fact, here we are operating
    # on a marking vector. This vector starts with the initial_marking expression's value.
    # Substitution value is marking vector index, multiset element #todo special case tuple/product sort
    #

    # See discussions on PnmlTuple, ProductSorts and variables.
    #^-------------------------------------
    #! This s a discussion of ENABLING rule
    #^-------------------------------------
    # c::Condition is attached to  t::Transition.
    # preset(net,pid(t)) ∪ postset(net,pid(t)) are the attached arcs.
    # arc inscription expressions have variable arguments as do conditions.

    # vars are ordered collections in standard! It uses Abstract Math and UML2 to say so.
    # They are the arguments to operators (expressions with variables), so the need to be consistent.

    # 0-ary operators are constants and literals (as ground terms without variables).
    # Rewriting should optimize/minimize these terms.

    # There will be inscriptions in preset(t) that are ground terms (constant or literal).
    # Use in postset is the obvious case: generate token.
    # A preset ground term inscription will not have a variable and use a multiplicity = 1.
    # Value will be of the basis sort (like all inscriptions).
    # The inscription is enabled if multiset[value] > 0, and value is removed on firing.
    # This is the same behavior as for PTNets that use integer-valued markings and inscriptions.

    #=
    #^-------------------------------------------------------------------------------------
    # binding value set
    #^-------------------------------------------------------------------------------------

    Collection of subsitution dictionaries created from binding value sets of all incriptions by selecting one from each set.
    length(1st set) * length(2nd set) * ... length(nth set)Condition
    Each dictionary is one substitution for every variable
    Dict(REFID => value in binding_value_set(REFID))

    sub = Dict{REFID,Ref{SORT}}()

    Ref{SORT}(multiset element) || Ref{SORT}(multiset element, tuple index)
        REFID may be repeated
            multiple of same var in an inscrition <= multplicity of a value in marking multiset
        &/or
            same var in multiple inscriptions all with same value

    for each subsitutuion tuple element
        sub(varid) maps the variable to a value
        Used in evaluating (c::Condition)() to filter the substituion collection

    for each preset(t) inscription
        bindings to marking values that satisfy the inscription.
        Only continue if all constraints are met, else return `false`.
        if var already has a binding only consider those values
            remove values from binding that do not satisfy this inscription
            value must be present in each marking of sufficent multiplicity
        #todo recursivly re-evaluate after each add?
    #^-------------------------------------

    =#
    #^ `PnmlTuple` that are `ProductSort` elements and julia `Tuple` are not the same.
    #^ The vars tuple may contain elements of a PnmlTuple. Use marking basis to decide.

    # variables are how an element of marking multiset is identified/assessed.
    # for each preset(t)
    #   - each element of each marking multiset is bound to the variable or variables  -> tuple of bindings
    #   - enabling rule returning true for a tuple of bindings adds tuple to enabled transition modes.

    # Generate JIT compiled code that uses REFID to update the VariableDeclaration
    # with arg reference information then applies/evaluates expression using the value.

    #? Each arg in iteratable ordered collection `args` is bound as the value of a
    #? pnml variable that appears within the expression tree rooted at `term`?

    # Varible in tree is a REFID to a VariableDeclaration that has the name and sort.
    # args are pairs of name (or REFID) and reference to marking value.

    # Reference to marking value is only read here as part of enabling function.

    # Make a copy of expression? Just during bring-up to verify same behavior & debug.
    # Simplify the expression by rewriting once (not each use).
    # The optimized expression still has variables at this point that are REFIDs.
    #


    # preset variables is a superset of postset variables.
    # Every postset variable is also a preset variable.
    # Variable is bound to preset marking value. #todo one reference for each occurance.
    # Used to remove from preset, add to potset.

    # foreach preset(t) arc inscription vars tuple
    #   enabling rule iterates matches for variable sort in marking multiset
    #   testing each binding combination in condition functor.

    # Will iterate over each preset(t) marking's multiset elements.
    # There will be (must be) a variable for each sort in the multiset basis.
    # PnmlTuples are unpacked into multiple variables.

    # Variables that appear in more than one preset(t) marking basis
    # must have the same value in each marking to be enabled

    #
    # enabling rule
    # marking - inscription - condition

    # firing rule
    # marking - inscription :: inscription - marking

    return cond_implementation(c, sub)
end

# color function?
function cond_implementation(c::Condition, sub::SubstitutionDict)
    for arg in keys(sub)
        @show arg
    end
    # BooleanEx is a literal. BoolExpr <: PnmlExpr can be non-literal (non-ground term).
    isa(term(c), BooleanEx) || @warn term(c) sub toexpr(term(c), sub) #! debug
    eval(toexpr(term(c), sub))::eltype(c) # Bool isa Number #todo! pnml variables
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
default_condition(::PnmlType) = Condition(BooleanEx(BooleanConstant(true)))
