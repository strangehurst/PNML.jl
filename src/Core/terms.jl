####################################################################################
#
####################################################################################

value(op::AbstractOperator) = error("value not defined for $(typeof(op))")

"return output sort of operator"
sortof(op::AbstractOperator) = error("sortof not defined for $(typeof(op))")

#==================================
 TermInterface version 0.4
    isexpr(x::T) # expression tree (S-expression) => head(x), children(x) required
    iscall(x::T) # call expression => operation(x), arguments(x) required
    head(x) # S-expression
    children(x) # S-expression
    operation(x) # if iscall(x)
    arguments(x) # if iscall(x)
    maketerm(T, head, children, type=nothing, metadata=nothing) # iff isexpr(x)
 Optional
    arity(x)
    metadata(x)
    symtype(expr)

:(arr[i, j]) == maketerm(Expr, :ref, [:arr, :i, :j])
:(f(a, b))   == maketerm(Expr, :call, [:f, :a, :b])

===================================#

"constants have arity of 0"
arity(op::AbstractOperator) = 0

"""
"""
expression(op::AbstractOperator) = error("expression not defined for $(typeof(op))")


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
    netid::Symbol # For DeclDict lookups.
end
tag(v::Variable) = v.variableDecl
netid(v::Variable) = v.netid
function (var::Variable)()
    _evaluate(var)
end
value(v::Variable) = begin
    println("value(::Variable) $(tag(v)) in $(netid(v)) needs access to DeclDict")
    dd = decldict(netid(v))
    @assert has_variable(dd, tag(v)) "$(tag(v)) not a variable declaration in $(netid(v))"
    return 0
end
_evaluate(v::Variable) = _evaluate(value(v))

sortof(v::Variable) = begin
    #println("sortof(::Variable) $(tag(v)) in $(netid(v)) needs access to DeclDict")
    #display(stacktrace())
    dd = decldict(netid(v))
    @assert has_variable(dd, tag(v)) "$(tag(v)) not a variable declaration in $(netid(v))"
    vdecl = variable(dd, tag(v))
    return sortof(vdecl)
end

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
Operator as Functor

tag maps to func
"""
struct Operator <: AbstractOperator
    tag::Symbol
    func::Function # Apply `func` to `in`: expressions evaluated with current variable values and constants.
    inexprs::Vector{PnmlExpr} # typeof(inexprs[i]) == eltype(insorts[i])
    insorts::Vector{AbstractSort} # Abstract inside vector is not terrible.
    outsort::AbstractSort
    #TODO have constructor validate typeof(inexprs[i]) == eltype(insorts[i])
    #=
    all((ex,so) -> typeof(ex) == eltype(so), zip(inexprs, insorts))
    =#
end
tag(op::Operator)    = op.tag
sortof(op::Operator) = op.outsort
inputs(op::Operator) = op.inexprs
function (op::Operator)()
    println("\n$(tag(op)) arity $(arity(op)) $(sortof(op))")
    @show input = [x() for x in inputs(op)] # evaluate each PnmlExpr
    @show typeof.(input) op.insorts eltype.(op.insorts)
    #@assert sortof.(input) == op.insorts #"expect two vectors that are pairwise equalSorts"
    @show out = op.func(input)
    @show isa(out, eltype(sortof(op)))
end
value(op::Operator)     = _evaluate(op)
_evaluate(op::Operator) = op() #TODO
arity(op::Operator)     = length(inputs(op))

function Base.show(io::IO, t::Operator)
    print(io, nameof(typeof(t)), "(")
    show(io, tag(t)); print(io, ", ");
    show(io, sortof(t)); print(io, ", ");
    show(io, inputs(t))
    print(io, ")")
end

#! add TermInteface here

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
struct Term <: AbstractTerm #! replace Term by PnmlExpr
    tag::Symbol
    elements::Any
end

tag(t::Term)::Symbol = t.tag #! replace Term by PnmlExpr
elements(t::Term) = t.elements #! replace Term by PnmlExpr
Base.eltype(t::Term) = typeof(elements(t)) #! replace Term by PnmlExpr
sortof(::Term) = IntegerSort() #! XXX XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
value(t::Term) = _evaluate(t()) # Value of a Term is the functor's value. #! empty vector?

function Base.show(io::IO, t::Term) #! replace Term by PnmlExpr
    #@show typeof(elements(t))
    print(io, nameof(typeof(t)), "(")
    show(io, tag(t)); print(io, ", ");
    dict_show(io, elements(t), 0)
    print(io, ")")
end

(t::Term)() =  _term_eval(elements(t)) #! replace Term by PnmlExpr

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

"""
Tuple in many-sorted algebra AST.Bool, Int, Float64, XDVT
"""
struct PnmlTuple <: AbstractOperator end

#=
PNML.Operator(:numberof, PNML.var"#103#104"(),
PnmlExpr[
    PNML.NumberConstant{Int64, PNML.PositiveSort}(3, PNML.PositiveSort()),
    PNML.DotConstant()], PNML.AbstractSort[PNML.PositiveSort(), PNML.DotSort()
    ],
    PNML.IntegerSort())
=#
"""
Some [`Operators`](@ref)` and [`Variables`](@ref) creates/use a multiset.
Wrap a Multisets.Multiset

multi`x where x is an instance of a sort T.
"""
struct PnmlMultiset{T} <: AbstractOperator #todo CamelCase
    ms::Multiset{T} #TODO allow real multiplicity
end
#PnmlMultiset(x) = PnmlMultiset(Multiset{sortof(x)}(x))
# TODO forward ops?

"""
$(TYPEDEF)
$(TYPEDFIELDS)

User operators refers to a [`NamedOperator`](@ref) declaration.
"""
struct UserOperator <: AbstractOperator
    declaration::Symbol # of a NamedOperator
    decldict::DeclDict # Shared with all of PnmlNet, is where the NamedOperator lives.
end
UserOperator(str::AbstractString, netid) = UserOperator(Symbol(str), netid)
UserOperator(decl::Symbol, netid) = UserOperator(decl, decldict(netid))

function(uo::UserOperator)(#= pass arguments to operator =#)
    @warn "UserOperator $uo.declaration needs access to DeclDict"
    no = named_op(uo.decldict, uo.declaration)
    no(#= pass arguments to operator =#)
end
sortof(uo::UserOperator) = sortof(named_op(decldict, uo.declaration))

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
