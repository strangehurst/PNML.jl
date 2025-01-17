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
#! From SymbolicUtils.jl NOTE: this is NOT TermInterface (a.k.a. PnmlExpr)
recurse_expr(ex::Expr, sub) = Expr(ex.head, recurse_expr.(ex.args, (sub,))...)
recurse_expr(ex, sub) = toexpr(ex, sub)

#recurse_expr(ex::PnmlExpr, sub) = Expr(ex.head, recurse_expr.(ex.args, (sub,))...)

"@matchable TermInterface expressions"
function TermInterface.maketerm(::Type{<:PnmlExpr}, head, children, metadata = nothing)
  head(children...)
end
# head and operation are the structure name, i.e. type/constructor
# children and arguments are the fields of the structure
# arity is length of fields
#

#! From Metatheory.jl. see also SymbolicUtils.substitute for recursive use of maketerm
# function to_expr(x::PatExpr)
#     if iscall(x)
#       maketerm(Expr, :call, [x.quoted_head; to_expr.(arguments(x))], nothing)
#     else
#       maketerm(Expr, operation(x), to_expr.(arguments(x)), nothing)
#     end
# end

# Metatheory.quoted_head: nameof(x) for Union{Function,DataType}), else identity
# All @matchable structs are iscall() so use Metatheory.quoted_head #todo cache?
# The other leg is for things that are not callable.
# NB: constructors are callable

# We also need to define equality for our matchables expression. Ignore any metadata.
function Base.:(==)(a::PnmlExpr, b::PnmlExpr)
    a.head == b.head && a.args == b.args && a.foo == b.foo #! is this corrct XXX
end

# TermInterface operators are s-expressions: first is function, rest are arguments.
# @matchable u>ses the struct name as head, making maketerm into a constructor call.

# from SymUtils.toexpr: Expr(:call, toexpr(op, st), map(x->toexpr(x, st), args)...)
# `st` is extra to the TermInterface operation and arguments.

#=
@matchable structs need a `maketerm`
After possible term rewriting there will be a recusive `toexpr` followed by `eval`.
This term (the @matchable) may not be at the root of the expression tree.

Selected abstracted expressions from pnml example files.

#^ Markings are ground terms (no variables).
#^ These expressions set the initial state of the net marking.
# What can a pnml tuple hold? The ISO Standard seems to think it is obvious (and don't say).
# The RelaxNG Schema says <tuple> it is a generic operator with >= 0 inputs and and 1 output.
# Usage suggests anything a marking may hold (is used as initial marking).
# A Tuple is an element of a ProductSort.
# Element Forms: useroperator, variable, expression.


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
    # sub::SubstitutionDict #! Ref ?
    refid::REFID # REFID in variables(). Accessed by variable(refid).
end
#! What is really wanted is SubstitutionDict[op.refid].
#! Where a non-ground expression is compiled into a method with a substitution dictionary as an argument.
# var(sub, id) = sub[id]
toexpr(op::VariableEx, var::SubstitutionDict) = begin
    @show var[op.refid] :($(var[op.refid]))
    :($(var[op.refid]))
end

function Base.show(io::IO, x::VariableEx)
    print(io, "VariableEx(", x.refid, ")" )
end

###################################################################################
# expression wrapping a REFID used to do operator lookup `operator(REFID)`.
@matchable struct UserOperatorEx <: OpExpr
    refid::REFID # operator(REFID) returns operator callable.
end
toexpr(op::UserOperatorEx, ::SubstitutionDict) = Expr(:call, operator, op.refid) # :(operator($(op.refid)))
function Base.show(io::IO, x::UserOperatorEx)
    print(io, "UserOperatorEx(", x.refid, ")" )
end
#! maketerm(Expr, :call, [:operator; op.refid], nothing)
#! Expr(:call, operator, op.refid)
#! Expr(:call, toexpr(c, m.head), toexpr.(Ref(c), m.args)...)
#! maketerm(Expr, :call, [x.quoted_head; to_expr.(arguments(x))], nothing)


###################################################################################
"""
Bag: a TermInterface expression calling pnmlmultiset(basis, x, multi) to construct
a [`PnmlMultiset`](@ref).

See [`Operator`](@ref) for another TermInterface operator.
"""
Bag # Need to avoid @matchable to have docstring
@matchable struct Bag <: PnmlExpr
    basis::UserSort # Wraps a sort REFID.
    element::Any # ground term expression
    multi::Any # multiplicity expression of element in a multiset
end
Bag(b, x) = Bag(b, x, 1) # singleton multiset
Bag(b) = Bag(b, nothing, nothing) # multiset: one of each element of the basis sort.

basis(b::Bag) = b.basis

toexpr(b::Bag, var::SubstitutionDict) = begin
    #^ Warning: can introduce a PnmlMultiset for element
    Expr(:call, pnmlmultiset, b.basis, toexpr(b.element, var), toexpr(b.multi, var))
end

function Base.show(io::IO, x::Bag)
    print(io, "Bag(",x.basis, ", ", x.element, ", ", x.multi,")"  )
end

###################################################################################
"""
    NumberEx

    TermInterface expression for a NumberSort.
"""
NumberEx # Need to avoid @matchable to have docstring
@matchable struct NumberEx{T<:Number} <: PnmlExpr
    basis::UserSort # Wraps a sort REFID.
    element::T #
end
NumberEx(x::Number) = NumberEx(sortref(x)::UserSort, x)
basis(x::NumberEx) = x.basis
toexpr(b::NumberEx, var::SubstitutionDict) = toexpr(b.element, var)
function Base.show(io::IO, x::NumberEx)
    print(io, "NumberEx(", x.basis, ", ", x.element,")")
end

"""
    BooleanEx

TermInterface expression for a BooleanSort.
"""
BooleanEx # Need to avoid @matchable to have docstring
@matchable struct BooleanEx <: BoolExpr
    element::BooleanConstant
end
basis(::BooleanEx) = usersort(:bool) # is constant
toexpr(b::BooleanEx, var::SubstitutionDict) = toexpr(b.element(), var) #todo eval isa ::eltype(b.basis)
function Base.show(io::IO, x::BooleanEx)
    print(io, "BooleanEx(", x.element,")")
end

###################################################################################
#& Multiset Operator
# struct All  <: PnmlExpr# #! :all is a literal, ground term, parsed as Bag expression
#     sort::REFID
# end
# struct Empty  <: PnmlExpr #! :empty is a literal, ground term, parsed as Bag expression
#     sort::REFID
# end

#"Multiset add: Bag × Bag -> PnmlMultiset"
@matchable struct Add <: PnmlExpr #^ multiset add uses `+` operator.
    args::Vector{Bag} # >=2 # TODO NTuplex[]
end
toexpr(op::Add, subdict::SubstitutionDict) = begin
    @assert length(op.args) >= 2
    #:($reduce(+, ($map(Fix2(toexpr,$var), $(op.args))...),))
    # println()
    # @show op.args
    # @show toexpr.(op.args, Ref(subdict))
    # xx = :(($(toexpr.(op.args, Ref(subdict))...),))
    # @show xx
    #dump(xx)
    #@show reduce(+, map(Fix2(toexpr,subdict), op.args)...)
    #Expr(:call, :reduce, :+, map(Fix2(toexpr,subdict), op.args)...) # constructs a new PnmlMultiset
    Expr(:call, sum, toexpr.(op.args, Ref(subdict))...) # constructs a new PnmlMultiset
end
function Base.show(io::IO, x::Add)
    print(io, "Add(", join(x.args, ", "), ")" )
end

#Expr(:ref, toexpr(args[1], states), toexpr.(args[2:end] .+ offset, (states,))...)


#"Multiset subtract: Bag × Bag -> PnmlMultiset"
@matchable struct Subtract <: PnmlExpr #^ multiset subtract uses `-` operator.
    lhs::Bag
    rhs::Bag
end
toexpr(op::Subtract, var::SubstitutionDict) = Expr(:call, :(-), toexpr(op.lhs, var), toexpr(op.rhs, var)) # :(toexpr($(op.lhs), $var) - toexpr($(op.rhs), $var))
function Base.show(io::IO, x::Subtract)
    print(io, "Subtract(", x.lhs, ", ", x.rhs, ")" )
end

#"Multiset integer scalar product: ℕ x Bag -> PnmlMultiset"
@matchable struct ScalarProduct <: PnmlExpr #^ multiset scalar multiply uses `*` operator.
    n::Any #! expression evaluating to integer, use Any to allow `Symbolic` someday.
    bag::Bag #! Bag is an expression
end
toexpr(op::ScalarProduct, var::SubstitutionDict) = Expr(:call, PnmlMultiset, basis(op.bag), Expr(:call, :(*), toexpr(op.n, var), toexpr(op.bag, var)))
#^:(PnmlMultiset(basis($(op.bag)), :(toexpr($$(op.n), $$var) * toexpr($$(op.bag), $$var))))

function Base.show(io::IO, x::ScalarProduct)
    print(io, "ScalarProduct(", x.n, ", ", bag, ")" )
end

# See parse_term(Val{:numberof}, returns Bag
# struct NumberOf # Bag, may be nonground term, must eval(toexpr) the value as multiset.
#     n::Any #! expression evaluating to integer >= 0
#     value::Any #! expression evaluating to a term
# end

@matchable struct Cardinality <: PnmlExpr #^ multiset cardinality uses `length`.
    arg::Any # multiset expression
end
toexpr(op::Cardinality, var::SubstitutionDict) = Expr(:call, :cardinality, toexpr(op.arg, var)) #:(length(toexpr($(op.arg).mset), $var)) #TODO

function Base.show(io::IO, x::Cardinality)
    print(io, "Cardinality(", x.arg, ")" )
end

@matchable struct CardinalityOf <: PnmlExpr #^ cardinalityof accesses multiset.
    ms::Any # multiset expression
    refid::REFID # element of basis sort
end
toexpr(op::CardinalityOf, var::SubstitutionDict) = Expr(:call, :multiplicity, toexpr(op.ms, var), op.refid) #:(toexpr($(op.ms, var).mset[op.refid]), $var)) #TODO
function Base.show(io::IO, x::CardinalityOf)
    print(io, "(CardinalityOf", x.ms, ", ", repr(refid), ")" )
end

#"Bag -> Bool"
@matchable struct Contains{T} <: PnmlExpr #^ multiset contains access multiset.
    ms::Any # multiset expression
    refid::Any
end
toexpr(op::Contains, var::SubstitutionDict) = Expr(:call, :(>), Expr(:call, :multiplicity, toexpr(op.ms, var), op.refid), 0)
#:(toexpr($(op.ms.mset[op.refid]), $var) >  0)
function Base.show(io::IO, x::Contains)
    print(io, "Contains(", x.ms, ", ", repr(refid), ")" )
end

#& Boolean Operators
@matchable struct Or <: BoolExpr #? Uses `||` operator.
    lhs::Any # BoolExpr
    rhs::Any # BoolExpr
end
toexpr(op::Or, var::SubstitutionDict) =  Expr(:call, :(||), toexpr(op.lhs, var), toexpr(op.rhs, var)) #:(toexpr($(op.lhs), $var) || toexpr($(op.rhs), $var))

function Base.show(io::IO, x::Or)
    print(io, "Or(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct And <: BoolExpr #? Uses `&&` operator.
    lhs::Any # BoolExpr
    rhs::Any # BoolExpr
end
toexpr(op::And, var::SubstitutionDict) = Expr(:call, :(&&), toexpr(op.lhs, var), toexpr(op.rhs, var)) #:(toexpr($(op.lhs), $var) && toexpr($(op.rhs), $var))
#!
function Base.show(io::IO, x::And)
    print(io, "And(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct Not <: BoolExpr #? Uses `!` operator.
    rhs::Any # BoolExpr
end
toexpr(op::Not, var::SubstitutionDict) = Expr(:call, :(!), toexpr(op.rhs, var)) #:(!(toexpr($(op.rhs), $var)))
function Base.show(io::IO, x::Not)
    print(io, "Not(", x.rhs, ")" )
end

@matchable struct Imply <: BoolExpr #? Uses `!` and `||` operators.
    lhs::Any # BoolExpr
    rhs::Any # BoolExpr
end
toexpr(op::Imply, var::SubstitutionDict) = Expr(:call, :(||), toexpr(op.lhs, var), toexpr(op.rhs, var)) #:(!toexpr($(op.lhs), $var) || toexpr($(op.rhs), $var))
function Base.show(io::IO, x::Imply)
    print(io, "Imply(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct Equality <: PnmlExpr #? Uses `==` operator.
    lhs::Any # expression evaluating to a T
    rhs::Any # expression evaluating to a T
end
toexpr(op::Equality, var::SubstitutionDict) = Expr(:call, :(==), toexpr(op.lhs, var), toexpr(op.rhs, var)) #:(toexpr($(op.lhs), $var) == toexpr($(op.rhs), $var))
function Base.show(io::IO, x::Equality)
    print(io, "Equality(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct Inequality <: PnmlExpr #? Uses `!=` operator.
    lhs::Any # expression evaluating to a T
    rhs::Any # expression evaluating to a T
end
toexpr(op::Inequality, var::SubstitutionDict) = Expr(:call, :(!=), toexpr(op.lhs, var), toexpr(op.rhs, var)) #:(toexpr($(op.lhs), $var) != toexpr($(op.rhs), $var))
function Base.show(io::IO, x::Inequality)
    print(io, "Inequality(", x.lhs, ", ", x.rhs, ")" )
end


#& Cyclic Enumeration Operators
@matchable struct Successor <: PnmlExpr
    arg::Any
end
toexpr(op::Successor, var::SubstitutionDict) = error("implement me arg ", repr(op.arg))
#! Expr(:call, :(||), toexpr(op.lhs, var), toexpr(op.rhs, var))
#! Expr(:call, toexpr(c, m.head), toexpr.(Ref(c), m.args)...)
function Base.show(io::IO, x::Successor)
    print(io, "Successor(", x.arg, ")" )
end

@matchable struct Predecessor <: PnmlExpr
    arg::Any
end
toexpr(op::Predecessor, var::SubstitutionDict) = error("implement me arg ", repr(op.arg))
function Base.show(io::IO, x::Predecessor)
    print(io, "Predecessor(", x.arg, ")" )
end


#& FiniteIntRange Operators work on integrs in spec, we extend to Number

#! Use the Integer version. The difference is how the number is accessed!
# struct LessThan{T <: Number} <: PnmlExpr #! Use the Integer version.
# struct LessThanOrEqual{T} <: PnmlExpr #! Use the Integer version.
# struct GreaterThan{T} <: PnmlExpr #! Use the Integer version.
# struct GreaterThanOrEqual{T} <: PnmlExpr #! Use the Integer version.


#& Integer # we extend to `Number`, really anything that supports the operator used:)
@matchable struct Addition <: PnmlExpr #? Use `+` operator.
    lhs::Any
    rhs::Any
end
toexpr(op::Addition, var::SubstitutionDict) = Expr(:call, :(+), toexpr(op.lhs, var), toexpr(op.rhs, var)) #:(toexpr($(op.lhs), $var) + toexpr($(op.rhs), $var))
function Base.show(io::IO, x::Addition)
    print(io, "Addition(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct Subtraction <: PnmlExpr #? Use `-` operator.
    lhs::Any
    rhs::Any
end
toexpr(op::Subtraction, var::SubstitutionDict) = :Expr(:call, :(-), toexpr(op.lhs, var), toexpr(op.rhs, var)) #(toexpr($(op.lhs), $var) - toexpr($(op.rhs), $var))
function Base.show(io::IO, x::Subtraction)
    print(io, "Subtraction(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct Multiplication <: PnmlExpr #? Use `*` operator.
    lhs::Any
    rhs::Any
end
toexpr(op::Multiplication, var::SubstitutionDict) = Expr(:call, :(*), toexpr(op.lhs, var), toexpr(op.rhs, var)) #:(toexpr($(op.lhs), $var) * toexpr($(op.rhs), $var))
function Base.show(io::IO, x::Multiplication)
    print(io, "Multiplication(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct Division <: PnmlExpr #? Use `div` operator.
    lhs::Any
    rhs::Any
end
toexpr(op::Division, var::SubstitutionDict) = Expr(:call, :div, toexpr(op.lhs, var), toexpr(op.rhs, var)) #:(div(toexpr($(op.lhs), $var), toexpr($(op.rhs), $var)))
function Base.show(io::IO, x::Division)
    print(io, "Division(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct GreaterThan <: PnmlExpr #? Use `>` operator.
    lhs::Any
    rhs::Any
end
toexpr(op::GreaterThan, var::SubstitutionDict) = Expr(:call, :(>), toexpr(op.lhs, var), toexpr(op.rhs, var)) #:(toexpr($(op.lhs), $var) > toexpr($(op.rhs), $var))
function Base.show(io::IO, x::GreaterThan)
    print(io, "GreaterThan(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct GreaterThanOrEqual <: PnmlExpr #? Use `>=` operator.
    lhs::Any
    rhs::Any
end
toexpr(op::GreaterThanOrEqual, var::SubstitutionDict) = Expr(:call, :(>=), toexpr(op.lhs, var), toexpr(op.rhs, var)) #:(toexpr($(op.lhs)) >= toexpr($(op.rhs), $var))
function Base.show(io::IO, x::GreaterThanOrEqual)
    print(io, "GreaterThanOrEqual(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct LessThan <: PnmlExpr #? Use `<` operator.
    lhs::Any
    rhs::Any
end
toexpr(op::LessThan, var::SubstitutionDict) = Expr(:call, :(<), toexpr(op.lhs, var), toexpr(op.rhs, var)) #:(toexpr($(op.lhs), $var) < toexpr($(op.rhs), $var))
function Base.show(io::IO, x::LessThan)
    print(io, "LessThan(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct LessThanOrEqual <: PnmlExpr #? Use `<=` operator.
    lhs::Any
    rhs::Any
end
toexpr(op::LessThanOrEqual, var::SubstitutionDict) = Expr(:call, :(<=), toexpr(op.lhs, var), toexpr(op.rhs, var)) #:(toexpr($(op.lhs), $var) <= toexpr($(op.rhs), $var))
function Base.show(io::IO, x::LessThanOrEqual)
    print(io, "LessThanOrEqual(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct Modulo <: PnmlExpr #? Use `mod` operator.
    lhs::Any
    rhs::Any
end
toexpr(op::Modulo, var::SubstitutionDict) = Expr(:call, :mod, toexpr(op.lhs, var), toexpr(op.rhs, var)) #:(mod(toexpr($(op.lhs), $var), toexpr($(op.rhs), $var)))
function Base.show(io::IO, x::Modulo)
    print(io, "Modulo(", x.lhs, ", ", x.rhs, ")" )
end


#& Partition
# PartitionElement is an operator declaration. Is this a literal?
@matchable struct PartitionElementOp <: OpExpr #! Same as PartitionElement, for term rerwite?
    id::Symbol
    name::Union{String,SubString{String}}
    refs::Vector{REFID} # to FEConstant
    partition::REFID
end
toexpr(op::PartitionElementOp, var::SubstitutionDict) = error("implement me ", repr(op))
#! Expr(:call, :(||), toexpr(op.lhs, var), toexpr(op.rhs, var))
function Base.show(io::IO, x::PartitionElementOp)
    print(io, "PartitionElementOp(", x.id, ", ", x.name, ", ", x.refs, ")" )
end

#> comparison functions on the partition elements which is based on
#> the order in which they occur in the declaration of the partition
@matchable struct PartitionLessThan <: PnmlExpr
    lhs::Any #PartitionElement
    rhs::Any #PartitionElement
    # return BoolExpr
end
toexpr(op::PartitionLessThan, var::SubstitutionDict) = error("implement me ", repr(op))
#! Expr(:call, :(||), toexpr(op.lhs, var), toexpr(op.rhs, var))
function Base.show(io::IO, x::PartitionLessThan)
    print(io, "PartitionLessThan(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct PartitionGreaterThan <: PnmlExpr
    lhs::Any #PartitionElement
    rhs::Any #PartitionElement
    # return BoolExpr
end
toexpr(op::PartitionGreaterThan, var::SubstitutionDict) = error("implement me ", repr(op))
#! Expr(:call, :(||), toexpr(op.lhs, var), toexpr(op.rhs, var))
function Base.show(io::IO, x::PartitionGreaterThan)
    print(io, "PartitionGreaterThan(", x.lhs, ", ", x.rhs, ")" )
end

# 0-arity despite the refpartition
@matchable struct PartitionElementOf <: PnmlExpr
    arg::Any
    refpartition::Any # UserSort, REFID
    # return PartitionElement
end
toexpr(op::PartitionElementOf, var::SubstitutionDict) = error("implement me ", repr(op))
#! Expr(:call, :(||), toexpr(op.lhs, var), toexpr(op.rhs, var))
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

#--------------------------------------------------------------
"""
    PnmlTupleEx(args::Vector)

PnmlTuple TermInterface expression object wraps an ordered collection of PnmlExpr objects.
There is a related `ProductSort`: an ordered collection of sorts.
Each tuple element will have the same sort as the corresponding product sort.


"""
PnmlTupleEx

@matchable struct PnmlTupleEx <: PnmlExpr #{N, T<:PnmlExpr}
    args::Vector{Any} # >=2 # TODO NTuple
    #x::NTuple{N,T}
end
toexpr(op::PnmlTupleEx, var::SubstitutionDict) = begin
    @error("implement me ", repr(op), " substitutions ", var)
    @assert length(op.args) >= 2
    Expr(:call, :PnmlTuple, toexpr.(op.args, Ref(var))...) #:(PnmlTuple($(map(Fix2(toexpr,var), op.args)...),))
end
function Base.show(io::IO, x::PnmlTupleEx)
    print(io, "PnmlTupleEx(", x.args, ")" )
end


##########################################################################################
# LiteralExpr from SymbolicUtils code.jl. Used by
# ModelingToolkit src/structural_transformation/codegen.jl and Symbolics.
# The "Literal" here is a reference to being non-Symbolic.
#
# Any term rewriting should be done before toexpr is called.
# For `st` we use variable substitution dictionary (or NamedTuple)
#
# ModelingToolkit has a Differential Equation focus,
# supports Real, Complex, (and maybe Quarterions, Octoions).
# And Linear Algebra.
# PNML is doing high-level petri nets with a multi-sorted algebra and a XML markup language.
#
# code.jl also uses @matchable, calling toexpr on the likes of
#   Assignment, Let, Func, MakeArray, etc.
#
##########################################################################################

"""
    LiteralExpr(ex)

Literally `ex`, an `Expr`. `toexpr` on `LiteralExpr` recursively calls
`toexpr` on any interpolated symbolic expressions.
"""
struct LiteralExpr
    ex
end
toexpr(exp::LiteralExpr, st) = recurse_expr(exp.ex, st)

#= Example Uses

function _make_sparse_array(arr, similarto, cse)
    if arr isa Union{SubArray, Base.ReshapedArray, LinearAlgebra.Transpose}
        LiteralExpr(quote
            $Setfield.@set $(nzmap(x->true, arr)).parent =
                $(_make_array(parent(arr), typeof(parent(arr)), cse))
            end)
    else
        LiteralExpr(quote
                        let __reference = copy($(nzmap(x->true, arr)))
                            $Setfield.@set __reference.nzval =
                            $(_make_array(arr.nzval, Vector{symtype(eltype(arr))}, cse))
                        end
                    end)
    end
end
#---------------
for j in jj
    push!(exprs, _set_array(LiteralExpr(:($out[$j])), nothing, rhss[j], checkbounds, skipzeros, cse))
end
LiteralExpr(quote
                $(exprs...)
            end)


#---------------
op_body = :(let $outsym = zeros(Float64, map(length, ($(shape(op)...),)))
            $body
        $outsym
    end) |> LiteralExpr

#---------------

=#

# SymbolicUtils substitute.jl

# """
#     substitute(expr, dict; fold=true)

# substitute any subexpression that matches a key in `dict` with
# the corresponding value. If `fold=false`,
# expressions which can be evaluated won't be evaluated.

# ```julia
# julia> substitute(1+sqrt(y), Dict(y => 2), fold=true)
# 2.414213562373095
# julia> substitute(1+sqrt(y), Dict(y => 2), fold=false)
# 1 + sqrt(2)
# ```
# """
# function substitute(expr, dict; fold=true)
#     haskey(dict, expr) && return dict[expr] #~ Substitute

#     if iscall(expr)
#         #~ Always susbtitute operation and arguments.
#         op = substitute(operation(expr), dict; fold=fold)
#         if fold
#             canfold = !(op isa Symbolic) #! what is Symbolic to US?
#             args = map(arguments(expr)) do x
#                 x′ = substitute(x, dict; fold=fold)
#                 canfold = canfold && !(x′ isa Symbolic) #! found Symbolic arg in tree.
#                 x′ #! to return substituted argument
#             end
#             canfold && return op(args...) #~ When no Symbolic in the expression tree, fold
#             args #! why is this here (to help compiler?)
#         else
#             args = map(x->substitute(x, dict; fold=fold), arguments(expr))
#         end

#         #~ Rewrite term after substitutions
#         maketerm(typeof(expr),
#                  op,
#                  args,
#                  metadata(expr))
#     else
#         expr #~ not a call
#     end
# end

"""
    substitute(expr, dict)

Recursivly substitute a VariableEx with its the value from `dict`.
The values in `dict` will be ground terms of a place's sorttype.
These values are from the current marking vector.
```
"""
function substitute(expr::PnmlExpr, var::SubstitutionDict)
    expr isa VariableEx && return var[expr.refid] #todo store marking vector index in dict.

    if iscall(expr) # all @matchable structs
        #~ Always substitute operation and arguments.
        op = substitute(operation(expr), var) #? is operation ever an expression?
        args = map(x->substitute(x, var), arguments(expr))

        #~ Rewrite term after substitutions
        maketerm(typeof(expr), op, args, metadata(expr))
    else
        expr #~ not a call, leave it alone
    end
end
# maketerm(typeof(expr), operation(expr), map(x->recurse_expr(x, dict), arguments(expr)), metadata(expr))
