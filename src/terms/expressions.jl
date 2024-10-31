# TermInterface infrastructure # 2024-10-17 seprated from operators#=
####################################################################################
##! add *MORE* TermInteface here
####################################################################################

#==================================
 TermInterface
:(arr[i, j]) == maketerm(Expr, :ref, [:arr, :i, :j]) #~ varaible?
:(f(a, b))   == maketerm(Expr, :call, [:f, :a, :b])  #~ operator

:(f()) == maketerm(Expr, :call, [:f])  #~ Operator is a constant when 0-airy Callable

variables are used in token firing rules.
Of all enabled firing modes for a transition one is chosen (randomly?).
Marking expressions are made of ground terms (without variables).
Arc inscriptiins and transition condition expessions may include variable terms.
Selecting a firing mode associates tokens with variables.
Transition firing removes tokens from input places and adds tokens into output places.
Variables in input inscription, output inscription and conditions are associated with same token sort.

variables: store in dictionary named "variables", key is PNML ID: maketerm(Expr, :ref, [:variables, :pid])

===================================#

"@matchable TermInterface expressions"
function TermInterface.maketerm(::Type{<:PnmlExpr}, head, children, metadata = nothing)
  head(children...)
end

# We also need to define equality for our matchables expression. Ignore any metadata.
function Base.:(==)(a::PnmlExpr, b::PnmlExpr)
    a.head == b.head && a.args == b.args && a.foo == b.foo #! is this corrct XXX
end

# TermInterface operators are s-expressions: first is function, rest are arguments.
# @matchable uses the struct name as head, making maketerm into a constructor call.

# from SymUtils.toexpr: Expr(:call, toexpr(op, st), map(x->toexpr(x, st), args)...)
# `st` is extra to the TermInterface operation and arguments.

#=
@matchable structs need a `maketerm`
After possible term rewriting there will be a recusive `toexpr` followed by `eval`.
This term (the @matchable) may not be at the root of the expression tree.

Selected abstracted expressins from pnml example files.

#^ Markings are ground terms (no variables).
#^ These expressions set the initial state of the net marking.
#TODO What can a pnml tuple hold? The ISO Standard seems to think it is obvious (and don't say).
#TODO Usage suggests anything a marking may hold.
initialMarking <- :all
initialMarking <- :tuple (:all,:all)
initialMarking <- :add subterms
initialMarking <- :numberof :numberconstant usersort #! explain sort
initialMarking <- :add :add :numbeof :numberconstant :tuple (:userop,:userop) :numbeof :numberconstant :tuple (:userop,:userop) :numbeof :numberconstant :tuple (:userop,:userop)
initialMarking <- :userop
initialMarking <- :numberof :numberconstant :variable #! is this correct?
initialMarking <- :tuple (:finiteintrangeconstant, :finiteintrangeconstant, :userop)

#^ Does a ground term make sense for either a condition or inscription expression?
#^ Yes. Inscriptions may set target marking to a constant value. Default values run to constants.
#^ Conditions set to constant true by default.
#~ These must be BoolExprs
condition <- :inequality :variable :variable
condition <- :or :equality :variable :userop :equality variable :userop
condition <- :or :equality :variable :variable :gtp :partelementof :variable :partelementof :variable
condition <- :and :gt :variable :numberconstant :gt :variable :numberconstant

#^ Expression that evaluates to either a tuple or a pnmlmultiset.
#^ Used to set a place's marking when a transition is fired. Remove from source, add to target.
inscription <- :tuple :variable :variable :userop
inscription <- :tuple :variable :finiteintrangeconstant :userop
inscription <- :numberof :numberconstant :tuple (:variable, :variable)
inscription <- :numberof :numberconstant :stringconstant
inscription <- :numberof :numberconstant :stringconcatenation :variable :variable
inscription <- :numberof :numberconstant :addition :variable :numberconstant
inscription <- :subtract :userop :numberconstant :tuple (:variable, :variable)
inscription <- :userop :variable :numberconstant
inscription <- :numberof :numberconstant :mult :variable :variable
=#


###################################################################################
# expression constructing a `Variable` wrapping a REFID to a `VariableDeclaration`.
@matchable struct VariableEx <: PnmlExpr
    refid::REFID # REFID in variables(). Accessed by variable(refid).
end
toexpr(op::VariableEx) = :($Variable($(op.refid)))
function Base.show(io::IO, x::VariableEx)
    print(io, "VariableEx(", x.refid, ")" )
end

###################################################################################
# expression wrapping a REFID used to do operator lookup `operator(REFID)`.
@matchable struct UserOperatorEx <: OpExpr
    refid::REFID # operator(REFID) returns operator callable.
end
toexpr(op::UserOperatorEx) = :(operator($(op.refid)))
function Base.show(io::IO, x::UserOperatorEx)
    print(io, "UserOperatorEx(", x.refid, ")" )
end

###################################################################################
"""
    Bag

TermInterface expression calling pnmlmultiset(basis, x, multi) to construct
a [`PnmlMultiset`](@ref).

See [`Operator`](@ref) for another TermInterface operator.
"""
Bag # Need to avoid @matchable to have docstring
@matchable struct Bag <: PnmlExpr
    basis::UserSort # Wraps a sort REFID.
    element::Any # eval(toexpr(element)) isa  eltype(basis). #! method unless nothing
    multi::Any # multiplicity of element #! must have toexpr() method unless nothing
end
Bag(b, x) = Bag(b, x, 1) # singleton multiset
Bag(b) = Bag(b, nothing, nothing) # multiset: one of each element of the basis sort.

basis(b::Bag) = b.basis

toexpr(b::Bag) = :($pnmlmultiset($(b.basis), toexpr($(b.element)), toexpr($(b.multi))))
#@show b.basis b.element b.multi #! causes eval

function Base.show(io::IO, x::Bag)
    print(io, "Bag(",x.basis, ",", x.element, ",", x.multi,")"  )
end

#& Multiset Operator
# struct All  <: PnmlExpr# #! :all is a literal, ground term, parsed as Bag expression
#     sort::REFID
# end
# struct Empty  <: PnmlExpr #! :empty is a literal, ground term, parsed as Bag expression
#     sort::REFID
# end

#"Multiset add: Bag × Bag -> PnmlMultiset"
@matchable struct Add <: PnmlExpr
    args::Vector{Bag} # >=2 # TODO NTuplex[]
end
toexpr(op::Add) = begin
    @assert length(op.args) >= 2
    :($reduce(+, ($(map(toexpr, op.args)...),))) # constructs a new PnmlMultiset
end
function Base.show(io::IO, x::Add)
    print(io, "Add(", x.args, ")" )
end

#"Multiset subtract: Bag × Bag -> PnmlMultiset"
@matchable struct Subtract <: PnmlExpr
    lhs::Bag
    rhs::Bag
end
toexpr(op::Subtract) = :(toexpr(toexpr(op.lhs)) - toexpr(toexpr(op.rhs)))
function Base.show(io::IO, x::Subtract)
    print(io, "Subtract(", x.lhs, ", ", x.rhs, ")" )
end

#"#Multiset integer scalar product: ℕ x Bag -> PnmlMultiset"
@matchable struct ScalarProduct <: PnmlExpr
    n::Any #! expression evaluating to integer, use Any to allow `Symbolic` someday.
    bag::Bag #! Bag is an expression
end
toexpr(op::ScalarProduct) = :(PnmlMultiset(basis(op.bag), :(toexpr(op.n) * toexpr(op.bag))))
function Base.show(io::IO, x::ScalarProduct)
    print(io, "ScalarProduct(", x.n, ", ", bag, ")" )
end

# See parse_term(Val{:numberof} ...
# struct NumberOf # Bag, may be nonground term, must eval(toexpr) the value as multiset.
#     n::Any #! expression evaluating to integer >= 0
#     value::Any #! expression evaluating to a term
# end

@matchable struct Cardinality <: PnmlExpr
    arg::Any # multiset expression
end
toexpr(op::Cardinality) = :(length(toexpr(op.arg).mset))
function Base.show(io::IO, x::Cardinality)
    print(io, "Cardinality(", x.arg, ")" )
end

@matchable struct CardinalityOf <: PnmlExpr
    ms::Any # multiset expression
    refid::REFID # element of basis sort
end
toexpr(op::CardinalityOf) = :(toexpr(op.ms).mset[op.refid])
function Base.show(io::IO, x::CardinalityOf)
    print(io, "(CardinalityOf", x.ms, ", ", repr(refid), ")" )
end

#"Bag -> Bool"
@matchable struct Contains{T} <: PnmlExpr
    ms::Any # multiset expression
    refid::Any
end
toexpr(op::Contains) = :(toexpr(op.ms).mset[op.refid] >  0)
function Base.show(io::IO, x::Contains)
    print(io, "Contains(", x.ms, ", ", repr(refid), ")" )
end

#& Boolean Operators
@matchable struct Or <: BoolExpr
    lhs::Any # BoolExpr
    rhs::Any # BoolExpr
end
toexpr(op::Or) = :(toexpr(toexpr(op.lhs)) || toexpr(op.rhs))
function Base.show(io::IO, x::Or)
    print(io, "Or(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct And <: BoolExpr
    lhs::Any # BoolExpr
    rhs::Any # BoolExpr
end
toexpr(op::And) = :(toexpr(toexpr(op.lhs)) && toexpr(op.rhs))
function Base.show(io::IO, x::And)
    print(io, "And(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct Not <: BoolExpr
    rhs::Any # BoolExpr
end
toexpr(op::Not) = :(!(toexpr(op.rhs)))
function Base.show(io::IO, x::Not)
    print(io, "Not(", x.rhs, ")" )
end

@matchable struct Imply <: BoolExpr
    lhs::Any # BoolExpr
    rhs::Any # BoolExpr
end
toexpr(op::Imply) = :(!toexpr(toexpr(op.lhs)) || toexpr(op.rhs))
function Base.show(io::IO, x::Imply)
    print(io, "Imply(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct Equality <: PnmlExpr
    lhs::Any # expression evaluating to a T
    rhs::Any # expression evaluating to a T
end
toexpr(op::Equality) = :(toexpr(op.lhs) == toexpr(op.rhs))
function Base.show(io::IO, x::Equality)
    print(io, "Equality(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct Inequality <: PnmlExpr
    lhs::Any # expression evaluating to a T
    rhs::Any # expression evaluating to a T
end
toexpr(op::Inequality) = :(toexpr(op.lhs) != toexpr(op.rhs))
function Base.show(io::IO, x::Inequality)
    print(io, "Inequality(", x.lhs, ", ", x.rhs, ")" )
end


#& Cyclic Enumeration Operators
@matchable struct Successor <: PnmlExpr
    arg::Any
end
toexpr(op::Successor) = error("implement me arg ", repr(op.arg))
function Base.show(io::IO, x::Successor)
    print(io, "Successor(", x.arg, ")" )
end

@matchable struct Predecessor <: PnmlExpr
    arg::Any
end
toexpr(op::Predecessor) = error("implement me arg ", repr(op.arg))
function Base.show(io::IO, x::Predecessor)
    print(io, "Predecessor(", x.arg, ")" )
end


#& FiniteIntRange Operators work on integrs in spec, we extend to Number
#=
#! Use the Integer version. The difference is how the number is accessed!
struct LessThan{T <: Number} <: PnmlExpr
    lhs::T
    rhs::T
end
struct LessThanOrEqual{T} <: PnmlExpr
    lhs::T
    rhs::T
end
struct GreaterThan{T} <: PnmlExpr
    lhs::T
    rhs::T
end
struct GreaterThanOrEqual{T} <: PnmlExpr
    lhs::T
    rhs::T
end
=#

#& Integer (we extend to generic Number)
@matchable struct Addition <: PnmlExpr
    lhs::Any
    rhs::Any
end
toexpr(op::Addition) = :(toexpr(op.lhs) + toexpr(op.rhs))
function Base.show(io::IO, x::Addition)
    print(io, "Addition(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct Subtraction <: PnmlExpr
    lhs::Any
    rhs::Any
end
toexpr(op::Subtraction) = :(toexpr(op.lhs) - toexpr(op.rhs))
function Base.show(io::IO, x::Subtraction)
    print(io, "Subtraction(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct Multiplication <: PnmlExpr
    lhs::Any
    rhs::Any
end
toexpr(op::Multiplication) = :(toexpr(op.lhs) * toexpr(op.rhs))
function Base.show(io::IO, x::Multiplication)
    print(io, "Multiplication(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct Division <: PnmlExpr
    lhs::Any
    rhs::Any
end
toexpr(op::Division) = :(div(toexpr(op.lhs), toexpr(op.rhs)))
function Base.show(io::IO, x::Division)
    print(io, "Division(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct GreaterThan <: PnmlExpr
    lhs::Any
    rhs::Any
end
toexpr(op::GreaterThan) = :(toexpr(op.lhs) > toexpr(op.rhs))
function Base.show(io::IO, x::GreaterThan)
    print(io, "GreaterThan(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct GreaterThanOrEqual <: PnmlExpr
    lhs::Any
    rhs::Any
end
toexpr(op::GreaterThanOrEqual) = :(toexpr(op.lhs) >= toexpr(op.rhs))
function Base.show(io::IO, x::GreaterThanOrEqual)
    print(io, "GreaterThanOrEqual(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct LessThan <: PnmlExpr # Everything is an expression here. #? NumExpr?
    lhs::Any
    rhs::Any
end
toexpr(op::LessThan) = :(toexpr(op.lhs) < toexpr(op.rhs))
function Base.show(io::IO, x::LessThan)
    print(io, "LessThan(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct LessThanOrEqual <: PnmlExpr
    lhs::Any
    rhs::Any
end
toexpr(op::LessThanOrEqual) = :(toexpr(op.lhs) <= toexpr(op.rhs))
function Base.show(io::IO, x::LessThanOrEqual)
    print(io, "LessThanOrEqual(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct Modulo <: PnmlExpr
    lhs::Any
    rhs::Any
end
toexpr(op::Modulo) = :(mod(toexpr(op.lhs), toexpr(op.rhs)))
function Base.show(io::IO, x::Modulo)
    print(io, "Modulo(", x.lhs, ", ", x.rhs, ")" )
end


#& Partition
# PartitionElement is an operator declaration. Is this a literal?
@matchable struct PartitionElementOp <: OpExpr #! Same as PartitionElement, for term rerwite?
    id::Symbol
    name::Union{String,SubString{String}}
    refs::Vector{REFID} # to FEConstant
end
toexpr(op::PartitionElementOp) = error("implement me")
function Base.show(io::IO, x::PartitionElementOp)
    print(io, "PartitionElementOp(", x.id, ", ", x.name, ", ", x.refs, ")" )
end

#> comparison functions on the partition elements which is based on
#> the order in which they occur in the declaration of the partition
@matchable struct PartitionLessThan{T} <: PnmlExpr
    lhs::T
    rhs::T
    # return BoolExpr
end
toexpr(op::PartitionLessThan) = error("implement me")
function Base.show(io::IO, x::PartitionLessThan)
    print(io, "PartitionLessThan(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct PartitionGreaterThan{T} <: PnmlExpr
    lhs::T
    rhs::T
    # return BoolExpr
end
toexpr(op::PartitionGreaterThan) = error("implement me ", repr(op))
function Base.show(io::IO, x::PartitionGreaterThan)
    print(io, "PartitionGreaterThan(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct PartitionElementOf <: PnmlExpr
    arg::Any
    refpartition::Any # UserSort, REFID
    # return BoolExpr
end
toexpr(op::PartitionElementOf) = error("implement me ", repr(op))
function Base.show(io::IO, x::PartitionElementOf)
    print(io, "PartitionElementOf(", x.arg, ", ", x.refpartition, ")" )
end

#& Strings
@matchable struct Concatenation{T <: AbstractString} <: PnmlExpr
    args::Vector{T} # =2
    # use ?
end

@matchable struct Append{T <: AbstractString} <: PnmlExpr
    lhs::T
    rhs::T
    # use ?
end

@matchable struct StringLength{T <: AbstractString} <: PnmlExpr
    arg::T
    # use ?
end

@matchable struct StringLessThan{T <: AbstractString} <: PnmlExpr
    lhs::T
    rhs::T
    # use ?
end

@matchable struct StringLessThanOrEqual{T <: AbstractString} <: PnmlExpr
    lhs::T
    rhs::T
    # use ?
end

@matchable struct StringGreaterThan{T <: AbstractString} <: PnmlExpr
    lhs::T
    rhs::T
    # use ?
end

@matchable struct StringGreaterThanOrEqual{T <: AbstractString} <: PnmlExpr
    lhs::T
    rhs::T
    # use ?
end

@matchable struct Substring{T <: AbstractString} <: PnmlExpr
    str::T
    start::Int
    length::Int
    # use ?
end

#& Lists
@matchable struct ListLength <: PnmlExpr
end

@matchable struct ListConcatenation <: PnmlExpr
end

@matchable struct Sublist <: PnmlExpr
end

@matchable struct ListAppend <: PnmlExpr
end

@matchable struct MemberAtIndex <: PnmlExpr
end
