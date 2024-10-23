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
    a.head == b.head && a.args == b.args && a.foo == b.foo
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

toexpr(b::Bag) = begin
    #@show b.basis b.element b.multi
    :($pnmlmultiset($(b.basis), $(b.element), $(b.multi)))
end
# Expr(:call, :pnmlmultiset, [b.basis, toexpr(b.x), toexpr(b.multi)])

#& Multiset Operator
# struct All  <: PnmlExpr# #! :all is a literal, ground term, parsed as Bag expression
#     sort::REFID
# end
# struct Empty  <: PnmlExpr #! :empty is a literal, ground term, parsed as Bag expression
#     sort::REFID
# end

@matchable struct Add <: PnmlExpr
    args::Vector{Bag} # >=2 #! maybe not ground term expressions TODO NTuplex[]
end
toexpr(op::Add) = begin # multiset add: Bag × Bag -> PnmlMultiset
    @assert length(op.args) >= 2
    quote
        $reduce(+, ($(map(toexpr, op.args)...),)) #! construct a new PnmlMultiset when evaluated!
    end
end

@matchable struct Subtract <: PnmlExpr
    lhs::Bag
    rhs::Bag
end
toexpr(op::Subtract) = begin # multiset difference returning a PnmlMultiset
    :(toexpr(op.lhs) - toexpr(op.rhs))
end

@matchable struct ScalarProduct <: PnmlExpr
    n::Any #! expression evaluating to integer, use Any to allow `Symbolic` someday.
    bag::Bag #! Bag is an expression
end
toexpr(op::ScalarProduct) = begin # returning a integer scalar product of PnmlMultiset
    :(PnmlMultiset(basis(op.bag), :(toexpr(op.n) * toexpr(op.bag))))
end

struct NumberOf # Bag, may be nonground term, must eval(toexpr) the value as multiset.
    n::Any #! expression evaluating to integer >= 0
    value::Any #! expression evaluating to a term
end

@matchable struct Cardinality <: PnmlExpr
    arg::Any # eval(toexp) to a multiset
end
toexpr(op::Cardinality) = begin
    :(length(toexpr(op.arg).mset))
end

@matchable struct CardinalityOf <: PnmlExpr
    ms::Any # multiset expression
    refid::REFID # element of basis sort
end
toexpr(op::CardinalityOf) = begin
    m = toexpr(op.ms)
    :($m.mset[op.refid])
end

@matchable struct Contains{T} <: PnmlExpr
    ms::Any # multiset expression
    refid::Any
end
toexpr(op::Contains) = begin
    m = toexpr(op.ms)
    :($(m.mset[op.refid]) >  0)
end

#& Boolean Operators
@matchable struct Or <: BoolExpr
    lhs::Any # BoolExpr
    rhs::Any # BoolExpr
end
toexpr(op::Or) = begin
    :(op.lhs || op.rhs)
end

@matchable struct And <: BoolExpr
    lhs::Any # BoolExpr
    rhs::Any # BoolExpr
end
toexpr(op::And) = begin
    :(op.lhs && op.rhs)
end

@matchable struct Not <: BoolExpr
    rhs::Any # BoolExpr
end
toexpr(op::Not) = begin
    :(!(op.rhs))
end

@matchable struct Imply <: BoolExpr
    lhs::Any # BoolExpr
    rhs::Any # BoolExpr
end
toexpr(op::Imply) = begin
    :(!op.lhs || op.rhs)
end

@matchable struct Equality{T} <: PnmlExpr
    lhs::T # expression evaluating to a T
    rhs::T # expression evaluating to a T
end
toexpr(op::Equality) = begin
    :(op.lhs == op.rhs)
end

@matchable struct Inequality{T} <: PnmlExpr
    lhs::T # expression evaluating to a T
    rhs::T # expression evaluating to a T
end
toexpr(op::Inequality) = begin
    :(op.lhs != op.rhs)
end


#& Cyclic Enumeration Operators
struct Successor <: PnmlExpr
    arg::Any
end
toexpr(op::Successor) = begin
    error("implement me")
end

struct Predecessor <: PnmlExpr
    arg::Any
end
toexpr(op::Predecessor) = begin
    error("implement me")
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

#& Partition
# PartitionElement is an operator declaration. Is this a literal?
struct PartitionElementOp <: PnmlExpr #! Same as PartitionElement, for term rerwite?
    id::Symbol
    name::Union{String,SubString{String}}
    refs::Vector{REFID} # to FEConstant
end
toexpr(op::PartitionElementOp) = begin
    error("implement me")
end

#> comparison functions on the partition elements which is based on
#> the order in which they occur in the declaration of the partition
struct PartitionLessThan{T} <: PnmlExpr
    lhs::T
    rhs::T
    # return BoolExpr
end
toexpr(op::PartitionLessThan) = begin
    error("implement me")
end

struct PartitionGreaterThan{T} <: PnmlExpr
    lhs::T
    rhs::T
    # return BoolExpr
end
toexpr(op::PartitionGreaterThan) = begin
    error("implement me")
end

struct PartitionElementOf <: PnmlExpr
    are::Any
    refpartition::Any # UserSort, REFID
    # return BoolExpr
end
toexpr(op::PartitionElementOf) = begin
    error("implement me")
end


#& Integer (we extend to generic Number)
struct Addition{T <: Number} <: PnmlExpr
    lhs::T
    rhs::T
    # use :(+)
end
toexpr(op::Addition) = begin
    error("implement me")
end

struct Subtraction{T <: Number} <: PnmlExpr
    lhs::T
    rhs::T
    # use :(-)
end
toexpr(op::Subtraction) = begin
    error("implement me")
end

struct Multiplication{T <: Number} <: PnmlExpr
    lhs::T
    rhs::T
    # use :(*)
end
struct Division{T <: Number}<: PnmlExpr
    lhs::T
    rhs::T
    # use :(/) or :(\div) or ?
end
struct GreaterThan{T <: Number}<: PnmlExpr
    lhs::T
    rhs::T
     # :(>) return BoolExpr
    end
struct GreaterThanOrEqual{T <: Number} <: PnmlExpr
    lhs::T
    rhs::T
     # :(>=) return BoolExpr
    end
struct LessThan{T <: Number} <: PnmlExpr
    lhs::T
    rhs::T
     # :(<) return BoolExpr
    end
struct LessThanOrEqual{T <: Number} <: PnmlExpr
    lhs::T
    rhs::T
     # :(<=) return BoolExpr
    end
struct Modulo{T <: Number} <: PnmlExpr
    lhs::T
    rhs::T
    # use ?
end

#& Strings
struct Concatenation{T <: AbstractString} <: PnmlExpr
    args::Vector{T} # =2
    # use ?
end
struct Append{T <: AbstractString} <: PnmlExpr
    lhs::T
    rhs::T
    # use ?
end
struct StringLength{T <: AbstractString} <: PnmlExpr
    arg::T
    # use ?
end
struct StringLessThan{T <: AbstractString} <: PnmlExpr
    lhs::T
    rhs::T
    # use ?
end
struct StringLessThanOrEqual{T <: AbstractString} <: PnmlExpr
    lhs::T
    rhs::T
    # use ?
end
struct StringGreaterThan{T <: AbstractString} <: PnmlExpr
    lhs::T
    rhs::T
    # use ?
end
struct StringGreaterThanOrEqual{T <: AbstractString} <: PnmlExpr
    lhs::T
    rhs::T
    # use ?
end
struct Substring{T <: AbstractString} <: PnmlExpr
    str::T
    start::Int
    length::Int
    # use ?
end

#& Lists
struct ListLength <: PnmlExpr
end
struct ListConcatenation <: PnmlExpr
end
struct Sublist <: PnmlExpr
end
struct ListAppend <: PnmlExpr
end
struct MemberAtIndex <: PnmlExpr
end
