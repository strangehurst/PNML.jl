####################################################################################
#
####################################################################################

"""
$(TYPEDEF)
Terms are part of the multi-sorted algebra that is part of a High-Level Petri Net.

An abstract type in the pnml XML specification, concrete `Term`s are
found within the <structure> element of a label.

Notably, a [`Term`](@ref) is not a PnmlLabel (or a PNML Label).

# References
See also [`Declaration`](@ref), [`SortType`](@ref), [`AbstractDeclaration`](@ref).

[Term_(logic)](https://en.wikipedia.org/wiki/Term_(logic)):
> A first-order term is recursively constructed from constant symbols, variables and function symbols.

> Besides in logic, terms play important roles in universal algebra, and rewriting systems.

> more convenient to think of a term as a tree.

> A term that doesn't contain any variables is called a ground term

> When the domain of discourse contains elements of basically different kinds,
> it is useful to split the set of all terms accordingly.
> To this end, a sort (sometimes also called type) is assigned to each variable and each constant symbol,
> and a declaration...of domain sorts and range sort to each function symbol....

[Type_theory](https://en.wikipedia.org/wiki/Type_theory)
> term in logic is recursively defined as a constant symbol, variable, or a function application, where a term is applied to another term

> if t is a term of type σ → τ, and s is a term of type σ, then the application of t to s, often written (t s), has type τ.

[Lambda terms](https://en.wikipedia.org/wiki/Lambda_calculus#Lambda_terms):
> The term redex, short for reducible expression, refers to subterms that can be reduced by one of the reduction rules.

See [Metatheory](https://github.com/JuliaSymbolics/Metatheory.jl)
and [SymbolicUtils](https://github.com/JuliaSymbolics/SymbolicUtils.jl)

"""
abstract type AbstractTerm end

_evaluate(x::AbstractTerm) = x() # functor

"""
$(TYPEDEF)
Part of the high-level pnml many-sorted algebra.

> ...can be a built-in constant or a built-in operator, a multiset operator which among others
> can construct a multiset from an enumeration of its elements, or a tuple operator.
> Each operator has a sequence of sorts as its input sorts, and exactly one output sort,
> which defines its signature.

See [`NamedOperator`](@ref) and [`ArbitraryOperator`](@ref).
"""
abstract type AbstractOperator <: AbstractTerm end
# Expect each instance to have fields:
# - definition of expression (PNML Term) that evaluates to an instance of an output sort.
# - ordered sequence of zero or more input sorts #todo vector or tuple?
# - one output sort
# and support methods to:
# - compare operator signatures for equality using sort eqality
# - output sort type to test against place sort type (and others)
#
# Note that a zero input operator is a constant.

"return output sort of operator"
sortof(op::AbstractOperator) = error("sortof not defined for $(typeof(op))")

"constants have arity of 0"
arity(op::AbstractOperator) = 0

"""
PnmlExpression (a.k.a. Term) is a Union{Variable,Operator}.
evaluating a Variable does a lookup to return value of an instance of a sort.
evaluating an Operator also returns value of an instance of a sort.
What is the value of a multiset? Multiplicity of 1 is trivial.
Also note that symmetric nets are restricted, do not allow places to be multiset.
The value will have eltype(sort) <: Number (if it is evaluatable).
Where is the MSA (multi-sorted algebra) defined?
"""
expression(op::AbstractOperator) = error("expression not defined for $(typeof(op))")

struct Operator <: AbstractOperator
    tag::Symbol
    out #!::Sort
    in::Vector{Any} #!{Sort}
end

"""
$(TYPEDEF)
$(TYPEDFIELDS)
Bool, Int, Float64, XDVT
Variable refers to a varaible declaration.
Example input: <variable refvariable="varx"/>.

#TODO examples of use, modifying and accessing
"""
struct Variable <: AbstractTerm
    variableDecl::Symbol
end

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Note that Term is an abstract element in the pnml specification with no XML tag, we call that `AbstractTerm`.
Here we use `Term` as a concrete wrapper around **unparsed** high-level many-sorted algebra terms
**AND EXTEND** to also wrapping "single-sorted" values for other PNTDs.

By adding `Bool`, `Int`, `Float64` it is possible for `PnmlCoreNet` and `ContinuousNet`
to use `Term`s, and for implenting `default_bool_term`, `default_one_term`, `default_zero_term`.

See also [`iscontinuous`](@ref)

As part of the many-sorted algebra AST attached to nodes of a High-level Petri Net Graph,
`Term`s are contained within the <structure> element of an annotation label.
One XML child is expected below <structure> in the PNML schema.
The child's XML tag is used as the AST node type symbol.
Usually [`unparsed_tag`](@ref) is used to turn the child into a key, value pair.

#TODO is it safe to assume that Bool, Int, Float64 are in the carrier set/basis set?

# Functor

    (t::Term)([default_one_term(HLCoreNet())])

Term as functor requires a default value for missing values.

As a preliminary implementation evaluate a HL term by returning `:value` in `elements` or
evaluating `default_one_term(HLCoreNet())`.

See [`parse_marking_term`](@ref), [`parse_condition_term`](@ref), [`parse_inscription_term`](@ref),  [`parse_type`](@ref), [`parse_sorttype_term`](@ref), [`AnyElement`](@ref).

**Warning:** Much of the high-level is WORK-IN-PROGRESS.
xs"""
struct Term <: AbstractTerm
    tag::Symbol
    elements::Any #! Vector{Any} #! {PnmlExpr} # includes Term
    #elements::Union{Bool, Int, Float64, XDVT} # concrete types #! too big for union splitting
    #! This should be replaced by Varible and AbstractOperator, handle union splitting there.
end
Term(s::AbstractString, e) = Term(Symbol(s), e) #~ Turn string into symbol.

tag(t::Term)::Symbol = t.tag
elements(t::Term) = t.elements
Base.eltype(t::Term) = typeof(elements(t))
sortof(::Term) = IntegerSort() #! XXX XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

value(t::Term) = _evaluate(t()) # Value of a Term is the functor's value. #! empty vector?

function Base.show(io::IO, t::Term)
    #@show typeof(elements(t))
    print(io, nameof(typeof(t)), "(")
    show(io, tag(t)); print(io, ", ");
    dict_show(io, elements(t), 0)
    print(io, ")")
end

(t::Term)() =  _term_eval(elements(t))

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

#(t::Term{Bool})(default = default_bool_term(HLCoreNet())) = begin end
#(t::Term{Int64})(default = default_one_term(HLCoreNet())) = begin end
#(t::Term{Float64})(default = default_one_term(HLCoreNet())) = begin end

"""
Schema 'Term' is better called 'PnmlExpr' since it is made of variables and operators.
An abstract syntax tree is formed in XML using <subterm> elements.
Leafs are variables and constants (operators of arity 0).
Arity > 0 operator's input sorts are the sorts of respective <subterm>.

"""
const PnmlExpr = Union{Variable, Operator, Term}


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
                          tag in builtin_constants ||
                          tag === :tuple || tag === :useroperator

"""
Tuple in many-sorted algebra AST.Bool, Int, Float64, XDVT
"""
struct PnmlTuple <: AbstractOperator end

"Create a multiset: multi`x"
struct numberof{T} <: AbstractOperator #todo CamelCase
    ms::Multiset{T} #TODO allow real multiplicity
end
numberof(x) = numberof(Multiset{sortof(x)}(x))

"""
$(TYPEDEF)
$(TYPEDFIELDS)

User operators refers to a [`NamedOperator`](@ref) declaration.
"""
struct UserOperator <: AbstractOperator
    declaration::Symbol # of a NamedOperator
end
UserOperator(str::AbstractString) = UserOperator(Symbol(str))

"""
$(TYPEDEF)
$(TYPEDFIELDS)

> ...arbitrary sorts and operators do not come with a definition of the sort or operation; they just introduce a new symbol without giving a definition for it.
"""
struct ArbitraryOperator{I<:AbstractSort} <: AbstractOperator
    declaration::Symbol
    input::Vector{AbstractSort} # Sorts
    output::I # sort of operator
end

#-----------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------
#
# PNML many-sorted algebra syntax tree term zoo follows.
#
#-----------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------

"""
Builtin operator NumberSorts
"""
struct NumberConstant{T<:Number, S<:NumberSort}
    value::T
    sort::S # value isa eltype(sort)
    # Schema allows a Term[], Not used. Part of generic operator xml structure?
end

#TODO Should be booleanconstant/numberconstant: one_term, zero_term, bool_term?

# Term is really Variable and Opeator
term_value_type(::Type{<:PnmlType}) = eltype(IntegerSort) #Int
term_value_type(::Type{<:AbstractContinuousNet}) = eltype(RealSort)  #Float64

"""
$(TYPEDSIGNATURES)

One as integer, float, or empty term with a value of one.
"""
function default_one_term end
default_one_term(pntd::PnmlType) = Term(:one, one(term_value_type(pntd)))
default_one_term(x::Any) = throw(ArgumentError("expected a PnmlType, got: $(typeof(x))"))

"""
$(TYPEDSIGNATURES)

Zero as integer, float, or empty term with a value of zero.
"""
function default_zero_term end
default_zero_term(pntd::PnmlType) = Term(:zero, zero(term_value_type(pntd)))
default_zero_term(x::Any) = throw(ArgumentError("expected a PnmlType, got: $(typeof(x))"))

"""
$(TYPEDSIGNATURES)

True as boolean or term with a value of `true`.
"""
function default_bool_term end
default_bool_term(pntd::PnmlType) = Term(:bool, true)
default_bool_term(x::Any) = throw(ArgumentError("expected a PnmlType, got: $(typeof(x))"))
