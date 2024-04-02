"""
Schema 'Term' is better called 'PnmlExpr' since it is made of variables and operators.
An abstract syntax tree is formed in XML using <subterm> elements.
Leafs are variables and constants (operators of arity 0).
Arity > 0 operator's input sorts are the sorts of respective <subterm>.

PnmlExpr (a.k.a. Term) is a Union{Variable,AbstractOperator}.
evaluating a Variable does a lookup to return value of an instance of a sort.
evaluating an Operator also returns value of an instance of a sort.
What is the value of a multiset? Multiplicity of 1 is trivial.
Also note that symmetric nets are restricted, do not allow places to be multiset.
The value will have eltype(sort) <: Number (if it is evaluatable).
Where is the MSA (multi-sorted algebra) defined?
"""
const PnmlExpr = Union{Variable, AbstractOperator}

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Note that Term is an abstract element in the pnml specification with no XML tag, we call that `AbstractTerm`.

As part of the many-sorted algebra AST attached to nodes of a High-level Petri Net Graph,
`Term`s are contained within the <structure> element of an annotation label or operator def.
One XML child is expected below <structure> in the PNML schema.
The child's XML tag is used as the AST node type symbol.

# Functor

Term as functor requires a default value for missing values.

See [`parse_marking_term`](@ref), [`parse_condition_term`](@ref), [`parse_inscription_term`](@ref),  [`parse_type`](@ref), [`parse_sorttype_term`](@ref), [`AnyElement`](@ref).

**Warning:** Much of the high-level is WORK-IN-PROGRESS.
"""
struct Term <: AbstractTerm #! replace Term by AbstractTerm
    tag::Symbol
    elements::Any
end

tag(t::Term)::Symbol = t.tag #! replace Term by AbstractTerm
elements(t::Term) = t.elements #! replace Term by AbstractTerm
Base.eltype(t::Term) = typeof(elements(t)) #! replace Term by AbstractTerm
sortof(::Term) = IntegerSort() #! XXX XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
value(t::Term) = _evaluate(t()) # Value of a Term is the functor's value. #! empty vector?

function Base.show(io::IO, t::Term) #! replace Term by AbstractTerm
    #@show typeof(elements(t))
    print(io, nameof(typeof(t)), "(")
    show(io, tag(t)); print(io, ", ");
    dict_show(io, elements(t), 0)
    print(io, ")")
end

(t::Term)() =  _term_eval(elements(t)) #! replace Term by AbstractTerm

_term_eval(v::Any) = error("Term elements of type $(typeof(v)) not supported")
_term_eval(v::Number) = v
_term_eval(v::AbstractString) = parse(Bool, v)
_term_eval(v::DictType) = begin
    # Fake like we know how to evaluate a expression of the high-level terms
    # by embedding a `value` in "our hacks". Like the ones that add sorts to non-high-level nets.
    !isnothing(get(v, :value, nothing)) && return _term_eval(v[:value])
    #haskey(v, :value) && return _term_eval(v[:value]) LittleDict don't work

    CONFIG.warn_on_unimplemented &&
        @error("_term_eval needs to handle pnml ast in `v`! returning `false`");
    #Base.show_backtrace(stdout, backtrace()) # Save for obscure bugs.
    return false #
end

#-----------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------

# Only One
isvariable(tag::Symbol) = tag === :variable

#-----------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------

#for sorts: integer, natural, positive
integer_operators = (:addition, # "Addition",
                     :subtraction, # "Subtraction",
                     :mult, # "Multiplication",
                     :div, # "Division",
                     :mod, # "Modulo",
                     :gt, # "GreaterThan",
                     :geq, # "GreaterThanOrEqual",
                     :lt, # "LessThan",
                     :leq, # "LessThanOrEqual",)
                    )
isintegeroperator(tag::Symbol) = tag in integer_operators
#integer_constants = (:one = one(Int), :zero = zero(Int))

multiset_operators = (:add,
                      :all,
                      :numberof,
                      :subtract,
                      :scalarproduct,
                      :empty,
                      :cardnality,
                      :cardnalitiyof,
                      :contains,
                      )
ismultisetoperator(tag::Symbol) = tag in multiset_operators

finite_operators  = (:lessthan,
                     :lessthanorequal,
                     :greaterthan,
                     :greaterthanorequal,
                     :finiteintrangeconstant,
                     )
isfiniteoperator(tag::Symbol) = tag in finite_operators

boolean_operators = (:or,
                     :and,
                     :imply,
                     :not,
                     :equality,
                     :inequality,
                    )
isbooleanoperator(tag::Symbol) = tag in boolean_operators

isbuiltinoperator(tag::Symbol) = tag in builtin_operators

# these are operators
builtin_constants = (:numberconstant,
                     :dotconstant,
                     :booleanconstant,
                     )

# boolean_constants = (:true, :false)
"""
    isoperator(tag::Symbol) -> Bool

Predicate to identify operators in the high-level pntd's many-sorted algebra abstract syntaxt tree.

# Extra
There is structure to operators:
  - integer
  - multiset
  - boolean
  - tuple
  - builtin constant
  - useroperator
"""
isoperator(tag::Symbol) = isintegeroperator(tag) ||
                          ismultisetoperator(tag) ||
                          isbooleanoperator(tag) ||
                          isfiniteoperator(tag) ||
                          tag in builtin_constants ||
                          tag === :tuple ||
                          tag === :useroperator

#-----------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------
#
# PNML many-sorted algebra syntax tree term zoo follows.
#
#-----------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------
#TODO Should be booleanconstant/numberconstant: one_term, zero_term, bool_term?

#-------------------------------------------------------------------------
# Term is really Variable and Opeator
term_value_type(::Type{<:PnmlType}) = eltype(IntegerSort) #Int
term_value_type(::Type{<:AbstractContinuousNet}) = eltype(RealSort)  #Float64

"""
$(TYPEDSIGNATURES)

One as integer, float, or empty term with a value of one.
"""
function default_one_term end
default_one_term(pntd::PnmlType) = NumberConstant(one(term_value_type(pntd)),IntegerSort())
default_one_term(x::Any) = throw(ArgumentError("expected a PnmlType, got: $(typeof(x))"))

"""
$(TYPEDSIGNATURES)

Zero as integer, float, or empty term with a value of zero.
"""
function default_zero_term end
default_zero_term(pntd::PnmlType) = NumberConstant(zero(term_value_type(pntd)), IntegerSort())
default_zero_term(x::Any) = throw(ArgumentError("expected a PnmlType, got: $(typeof(x))"))

"""
$(TYPEDSIGNATURES)

True as boolean or term with a value of `true`.
"""
function default_bool_term end
default_bool_term(::PnmlType) = BooleanConstant(true)
default_bool_term(x::Any) = throw(ArgumentError("expected a PnmlType, got: $(typeof(x))"))
