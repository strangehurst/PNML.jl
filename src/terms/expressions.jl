"""
Expressions Module
"""
module Expressions

using Base: Fix2
using TermInterface

import Metatheory
using Metatheory: @matchable

using PNML
using PNML: BooleanConstant, FEConstant , feconstant, ProductSort
using PNML: pnmlmultiset, operator, partitionsort
import PNML: basis, sortref, sortof, sortelements, sortdefinition

export toexpr

export PnmlExpr, BoolExpr, OpExpr # abstract types
# concrete types
export VariableEx, UserOperatorEx, PnmlTupleEx, NumberEx, BooleanEx
export DotConstantEx
export Bag, Add, Subtract, ScalarProduct, Cardinality, CardinalityOf, Contains
export And, Or, Not, Imply, Equality, Inequality, Successor, Predecessor
export PartitionLessThan, PartitionGreaterThan, PartitionElementOf
export Addition, Subtraction, Multiplication, Division
export GreaterThan, GreaterThanOrEqual, LessThan, LessThanOrEqual, Modulo
export Concatenation, Append, StringLength, SubstringEx
export StringLessThan, StringLessThanOrEqual, StringGreaterThan, StringGreaterThanOrEqual
export ListEx, ListLength, ListConcatenation, Sublist, ListAppend, MemberAtIndex
export expr_sortref


"""
TermInterface expression types.
"""
abstract type PnmlExpr end

"""
TermInterface boolean expression types.

All boolean expressions have a known sort `:bool`.
"""
abstract type BoolExpr <: PnmlExpr end
basis(::BoolExpr) = NamedSortRef(:bool)
sortref(::BoolExpr) = NamedSortRef(:bool)
expr_sortref(b::BoolExpr; ddict) = sortref(b)::AbstractSortRef

"""
TermInterface operator expression types.
"""
abstract type OpExpr <: PnmlExpr end

"""
    toexpr(ex::PnmlExpr, varsubs::NamedTuple{REFID,Any}, ddict) -> Expr

Return `Expr` constructed from `ex`. Call `toexpr` on any contained terms.
`varsubs` used to replace variables in expressions.
"""
function toexpr end

# Some expressions are ground terms that have no variables.
toexpr(::Nothing, ::NamedTuple, ddict) = nothing
toexpr(x::T, ::NamedTuple, ddict) where {T <: Number} = identity(x) #! literal
toexpr(s::Symbol, ::NamedTuple, ddict) = QuoteNode(s)
function toexpr(t::Tuple, vsub::NamedTuple, ddict)
    isempty(vsub) || @error "variable substitutions NOT Empty: " t vsub
    return t
end

toexpr(nc::PNML.NumberConstant, ::NamedTuple, ddict) = value(nc)
toexpr(c::PNML.FiniteIntRangeConstant, ::NamedTuple, ddict) = value(c)
toexpr(::PNML.DotConstant, ::NamedTuple, ddict) = PNML.DotConstant(ddict)
toexpr(c::PNML.BooleanConstant, ::NamedTuple, ddict) = value(c)

"""
    expr_sortref(v::PnmlExpr; ddict) -> AbstractSortRef

Return concrete AbstractSortRef of PnmlExpr. Sometimes aliased to `basis`, `sortref`.
"""
function expr_sortref end

# TermInterface infrastructure
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
recurse_expr(ex::Expr, varsub::NamedTuple, ddict) = Expr(ex.head, recurse_expr.(ex.args, (varsub,))...)
recurse_expr(ex::Any, varsub::NamedTuple, ddict) = toexpr(ex, varsub, ddict)

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

# Metatheory.quoted_head: nameof(x) for Union{Function,DataType}), else identity.
# All @matchable structs are iscall() so use Metatheory.quoted_head #todo cache?
# The other leg is for things that are not callable.
# NB: constructors are callable

# We also need to define equality for our matchables expression. Ignore any metadata.
function Base.:(==)(a::PnmlExpr, b::PnmlExpr)
    a.head == b.head && a.args == b.args && a.foo == b.foo #! is this corrct XXX
end

###################################################################################
# expression constructing a `Variable` wrapping a REFID to a `VariableDeclaration`.
@matchable struct VariableEx <: PnmlExpr
    refid::REFID #  Varia
end

function toexpr(op::VariableEx, varsub::NamedTuple, ddict)
    # `op` holds `refid`, an index into a `DeclDict` operator dictionary.
    # `varsub`
    vsub = varsub[op.refid]
    if vsub isa Symbol
        Expr(:call, feconstant, QuoteNode(ddict), QuoteNode(vsub))
    else
        :($(vsub))
    end
end

expr_sortref(v::VariableEx; ddict) = sortref(PNML.variabledecl(ddict, v.refid))::AbstractSortRef

function Base.show(io::IO, x::VariableEx)
    print(io, "VariableEx(", x.refid, ")" )
end

###################################################################################
# expression wrapping a REFID used to do operator lookup `operator(ddict, REFID)`.
@matchable struct UserOperatorEx <: OpExpr
    refid::REFID # operator(ddict, REFID) returns operator callable.
end

function toexpr(op::UserOperatorEx, varsub::NamedTuple, ddict)
    #@warn "toexpr(op::UserOperatorEx, varsub::NamedTuple)" op varsub operator(ddict, op.refid)
    Expr(:call, operator, QuoteNode(ddict), QuoteNode(op.refid)) #
end

function expr_sortref(o::UserOperatorEx; ddict)
    #todo or other constant/operator
    return sortref(PNML.feconstant(ddict, o.refid))::AbstractSortRef
end

function Base.show(io::IO, x::UserOperatorEx)
    print(io, "UserOperatorEx(", x.refid, ")" )
end


###################################################################################
@matchable struct NamedOperatorEx <: OpExpr
    refid::REFID # operator(ddict, REFID) returns operator callable.
end

function toexpr(op::NamedOperatorEx, varsub::NamedTuple, ddict)
    Expr(:call, operator, QuoteNode(ddict), QuoteNode(op.refid)) #
end

function expr_sortref(o::NamedOperatorEx; ddict)
    #todo or other constant/operator
    return sortref(PNML.feconstant(ddict, o.refid))::AbstractSortRef
end

function Base.show(io::IO, x::NamedOperatorEx)
    print(io, "NamedOperatorEx(", x.refid, ")" )
end


###################################################################################
"""
Bag: a TermInterface expression calling pnmlmultiset(basis, x, multi) to construct
a [`PNML.PnmlMultiset`](@ref).

See [`PNML.Operator`](@ref) for another TermInterface operator.
"""
Bag # Need to avoid @matchable to have docstring
@matchable struct Bag{S <: AbstractSortRef} <: PnmlExpr
    basis::S # Wraps a sort REFID.
    element::Any # ground term expression
    multi::Any # multiplicity expression of element in a multiset
    # Bag(b, x, m) = begin
    #     # if x isa PnmlTupleEx
    #     #     @error "bag element is tuple" b x m
    #     # end
    #     new(b, x, m)
    # end
end
Bag(b, x) = Bag(b, x, 1) # singleton multiset
Bag(b) = Bag(b, nothing, nothing) # multiset: one of each element of the basis sort.

sortref(b::Bag) = b.basis
basis(b::Bag) = b.basis
expr_sortref(b::Bag; ddict) = sortref(b)::AbstractSortRef # also basis

function toexpr(b::Bag, varsub::NamedTuple, ddict)
    #@show b varsub Expr(:parameters, Expr(:kw,:ddict, ddict))
    #^ Warning: b.element can be: `PnmlMultiset`, `pnmltuple`
    #^ tuples are elements of a `ProductSort`
    Expr(:call, pnmlmultiset,
        Expr(:parameters, Expr(:kw, :ddict, ddict)), # keyword arguments
        b.basis,
        toexpr(b.element, varsub, ddict),
        toexpr(b.multi, varsub, ddict))

end

function Base.show(io::IO, x::Bag)
    print(io, "Bag(",x.basis, ", ", x.element, ", ", x.multi,")"  )
end

###################################################################################
"""
    NumberEx

    TermInterface expression for a `<numberconstant>`.
"""
NumberEx # Need to avoid @matchable to have docstring
@matchable struct NumberEx{T<:Number, S <: AbstractSortRef} <: PnmlExpr
    basis::S # Wraps a sort REFID.
    element::T #
end

toexpr(b::NumberEx{T}, var::NamedTuple, ddict) where {T<:Number} = b.element

basis(x::NumberEx) = x.basis
sortref(x::NumberEx) = x.basis
expr_sortref(x::NumberEx; ddict) = basis(x)::AbstractSortRef

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

function toexpr(b::BooleanEx, var::NamedTuple, ddict)
    if b.element isa BooleanConstant
        QuoteNode(PNML.Labels.value(b.element))
    else
        toexpr(b.element, var::NamedTuple, ddict)
    end
end

function Base.show(io::IO, x::BooleanEx)
    print(io, "BooleanEx(", x.element,")")
end

"""
    DotConstantEx

TermInterface expression for a DotSort element.
"""
DotConstantEx # Need to avoid @matchable to have docstring
@matchable struct DotConstantEx <: PnmlExpr
end

basis(::DotConstantEx) = UserSortRef(:dot)
sortref(::DotConstantEx) = UserSortRef(:dot)
expr_sortref(x::DotConstantEx; ddict) = basis(x)::AbstractSortRef

function toexpr(b::DotConstantEx, var::NamedTuple, ddict)
    QuoteNode(PNML.DotConstant(ddict))
end

function Base.show(io::IO, x::DotConstantEx)
    print(io, "DotConstantEx()")
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
    args::Vector{Bag} # >=2 =
end

basis(a::Add) = basis(first(a.args))
sortref(a::Add) = sortref(first(a.args))
expr_sortref(a::Add; ddict) = expr_sortref(first(a.args); ddict)::AbstractSortRef

function toexpr(op::Add, varsub::NamedTuple, ddict)
    @assert length(op.args) >= 2
    # Expr(:call, sum, [eval(toexpr(arg, varsub, ddict)) for arg in op.args])
    :(sum(eval(toexpr(arg, $varsub, $ddict)) for arg in $(op.args))) # creates PnmlMultiset
end

function Base.show(io::IO, x::Add)
    print(io, "Add(", join(x.args, ", "), ")" )
end

#"Multiset subtract: Bag × Bag -> PnmlMultiset"
@matchable struct Subtract <: PnmlExpr #^ multiset subtract uses `-` operator.
    lhs::Bag
    rhs::Bag
end

basis(a::Subtract) = basis(a.lhs)
sortref(a::Subtract) = sortref(a.lhs)
expr_sortref(a::Subtract; ddict) = expr_sortref(a.lhs; ddict)::AbstractSortRef

function toexpr(op::Subtract, var::NamedTuple, ddict)
    Expr(:call, :(-), toexpr(op.lhs, var, ddict), toexpr(op.rhs, var, ddict))
end

function Base.show(io::IO, x::Subtract)
    print(io, "Subtract(", x.lhs, ", ", x.rhs, ")" )
end

#"Multiset integer scalar product: ℕ x Bag -> PnmlMultiset"
@matchable struct ScalarProduct <: PnmlExpr #^ multiset scalar multiply uses `*` operator.
    n::Any #! Expression evaluating to integer, use Any to allow `Symbolic` someday.
    bag::Bag #! Expression
end

basis(a::ScalarProduct) = basis(a.bag)
sortref(a::ScalarProduct) = sortref(a.bag)
expr_sortref(a::ScalarProduct; ddict) = expr_sortref(a.bag; ddict)::AbstractSortRef

function toexpr(op::ScalarProduct, var::NamedTuple, ddict)
    Expr(:call, PNML.PnmlMultiset, basis(op.bag)::AbstractSortRef,
        Expr(:call, :(*), toexpr(op.n, var, ddict), toexpr(op.bag, var, ddict)))
end

function Base.show(io::IO, x::ScalarProduct)
    print(io, "ScalarProduct(", x.n, ", ", bag, ")" )
end

# See parse_term(Val{:numberof}, returns Bag
# struct NumberOf
#     n::Any #! Expression evaluating to integer >= 0
#     value::Any #! Expression evaluating to a term
# end

@matchable struct Cardinality{S <: AbstractSortRef} <: PnmlExpr #^ multiset cardinality uses `length`.
    bag::Bag{S} # multiset expression
end

basis(::Cardinality) = UserSortRef(:natural)
sortref(::Cardinality) = UserSortRef(:natural)
expr_sortref(a::Cardinality; ddict) = sortref(a)::AbstractSortRef

function toexpr(op::Cardinality, var::NamedTuple, ddict)
    Expr(:call, :cardinality, toexpr(op.bag, var, ddict))
end

function Base.show(io::IO, x::Cardinality)
    print(io, "Cardinality(", x.arg, ")" )
end

@matchable struct CardinalityOf{S <: AbstractSortRef} <: PnmlExpr #^ cardinalityof accesses multiset.
    ms::Bag{S} # multiset expression
    refid::REFID # element of basis sort
end

function toexpr(op::CardinalityOf, var::NamedTuple, ddict)
    Expr(:call, :multiplicity, toexpr(op.ms, var, ddict), op.refid)
end

function Base.show(io::IO, x::CardinalityOf)
    print(io, "(CardinalityOf", x.ms, ", ", repr(refid), ")" )
end

#"Bag -> Bool"
@matchable struct Contains{S <: AbstractSortRef} <: BoolExpr #^ multiset contains access multiset.
    lhs::Bag{S} # multiset expression
    rhs::Bag{S} # multiset expression

end

function toexpr(op::Contains, var::NamedTuple, ddict)
    Expr(:call, :(>), Expr(:call, :contains, toexpr(op.lhs, var, ddict), toexpr(op.rhs, var, ddict)))
end

function Base.show(io::IO, x::Contains)
    print(io, "Contains(", x.ms, ", ", repr(refid), ")" )
end

#& Boolean Operators
@matchable struct Or <: BoolExpr #^ Uses `any`.
    args::Vector{BoolExpr} # >=2 in ISO 15909, but some =1 exist.
end

function toexpr(op::Or, vars::NamedTuple, ddict)
    :(any(eval(toexpr(arg, $vars, $ddict)) for arg in $(op.args)))
end

function Base.show(io::IO, x::Or)
    print(io, "Or(", join(x.args, ", "), ")" )
end

@matchable struct And <: BoolExpr #^ Uses `all`.
    args::Vector{BoolExpr} # >=2
end

function toexpr(op::And, vars::NamedTuple, ddict)
    #@show [eval(toexpr(arg, vars, ddict)) for arg in op.args]
    :(all(eval(toexpr(arg, $vars, $ddict)) for arg in $(op.args)))
end

function Base.show(io::IO, x::And)
    print(io, "And(", join(x.args, ", "), ")" )
end

@matchable struct Not <: BoolExpr #^ Uses `!` operator.
    args::Vector{BoolExpr} # >=2
    #! rhs::Any # BoolExpr #todo handle ordered collection. return and of not.boolean
end

#~  !any(true) === all(!true)
function toexpr(op::Not, vars::NamedTuple, ddict)
    :(!any(eval(toexpr(arg, $vars, $ddict)) for arg in $(op.args)))
end

function Base.show(io::IO, x::Not)
    print(io, "Not(", x.args, ")" )
end

@matchable struct Imply <: BoolExpr #^ Uses `!` and `||` operators.
    lhs::Any # BoolExpr
    rhs::Any # BoolExpr
end

function toexpr(op::Imply, var::NamedTuple, ddict)
    Expr(:call, :(||), toexpr(op.lhs, var, ddict), toexpr(op.rhs, var, ddict))
end

function Base.show(io::IO, x::Imply)
    print(io, "Imply(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct Equality <: BoolExpr #^ Uses `==` operator.
    lhs::Any # expression evaluating to a T
    rhs::Any # expression evaluating to a T
end

function toexpr(op::Equality, var::NamedTuple, ddict)
    Expr(:call, :(==), toexpr(op.lhs, var, ddict), toexpr(op.rhs, var, ddict))
end

function Base.show(io::IO, x::Equality)
    print(io, "Equality(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct Inequality <: BoolExpr #^ Uses `!=` operator.
    lhs::Any # expression evaluating to a T
    rhs::Any # expression evaluating to a T
end

function toexpr(op::Inequality, var::NamedTuple, ddict)
    Expr(:call, :(!=), toexpr(op.lhs, var, ddict), toexpr(op.rhs, var, ddict))
end

function Base.show(io::IO, x::Inequality)
    print(io, "Inequality(", x.lhs, ", ", x.rhs, ")" )
end


#& Cyclic Enumeration Operators
@matchable struct Successor <: PnmlExpr
    arg::Any
end

toexpr(op::Successor, var::NamedTuple, ddict) = error("implement me arg ", repr(op.arg))
#! Expr(:call, :(||), toexpr(op.lhs, var), toexpr(op.rhs, var))
#! Expr(:call, toexpr(c, m.head), toexpr.(Ref(c), m.args)...)

function Base.show(io::IO, x::Successor)
    print(io, "Successor(", x.arg, ")" )
end

@matchable struct Predecessor <: PnmlExpr
    arg::Any
end

toexpr(op::Predecessor, var::NamedTuple, ddict) = error("implement me arg ", repr(op.arg))

function Base.show(io::IO, x::Predecessor)
    print(io, "Predecessor(", x.arg, ")" )
end


#& FiniteIntRange Operators work on integrs in spec, we extend to Number

#! Use the Integer version. The difference is how the number is accessed!
# struct LessThan{T <: Number} <: PnmlExpr #! Use the Integer version.
# struct LessThanOrEqual{T} <: PnmlExpr #! Use the Integer version.
# struct GreaterThan{T} <: PnmlExpr #! Use the Integer version.
# struct GreaterThanOrEqual{T} <: PnmlExpr #! Use the Integer version.


#& Integer in standard # we extend to `Number`, really anything that supports the + operator used:)
@matchable struct Addition <: PnmlExpr #? Use `+` operator.
    lhs::Any
    rhs::Any
end

expr_sortref(a::Addition; ddict) = expr_sortref(a.lhs; ddict)::AbstractSortRef

function toexpr(op::Addition, var::NamedTuple, ddict)
    Expr(:call, :(+), toexpr(op.lhs, var, ddict), toexpr(op.rhs, var, ddict))
end

function Base.show(io::IO, x::Addition)
    print(io, "Addition(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct Subtraction <: PnmlExpr #? Use `-` operator.
    lhs::Any
    rhs::Any
end

expr_sortref(a::Subtraction; ddict) = expr_sortref(a.lhs; ddict)::AbstractSortRef

function toexpr(op::Subtraction, var::NamedTuple, ddict)
    Expr(:call, :(-), toexpr(op.lhs, var, ddict), toexpr(op.rhs, var, ddict))
end

function Base.show(io::IO, x::Subtraction)
    print(io, "Subtraction(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct Multiplication <: PnmlExpr #? Use `*` operator.
    lhs::Any
    rhs::Any
end

expr_sortref(a::Multiplication; ddict) = expr_sortref(a.lhs; ddict)::AbstractSortRef

function toexpr(op::Multiplication, var::NamedTuple, ddict)
    Expr(:call, :(*), toexpr(op.lhs, var, ddict), toexpr(op.rhs, var, ddict))
end

function Base.show(io::IO, x::Multiplication)
    print(io, "Multiplication(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct Division <: PnmlExpr #? Use `div` operator.
    lhs::Any
    rhs::Any
end

expr_sortref(a::Division; ddict) = expr_sortref(a.lhs; ddict)::AbstractSortRef

function toexpr(op::Division, var::NamedTuple, ddict)
    Expr(:call, :div, toexpr(op.lhs, var, ddict), toexpr(op.rhs, var, ddict))
end

function Base.show(io::IO, x::Division)
    print(io, "Division(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct GreaterThan <: BoolExpr #? Use `>` operator.
    lhs::Any
    rhs::Any
end

function toexpr(op::GreaterThan, var::NamedTuple, ddict)
    Expr(:call, :(>), toexpr(op.lhs, var, ddict), toexpr(op.rhs, var, ddict))
end

function Base.show(io::IO, x::GreaterThan)
    print(io, "GreaterThan(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct GreaterThanOrEqual <: BoolExpr #? Use `>=` operator.
    lhs::Any
    rhs::Any
end

function toexpr(op::GreaterThanOrEqual, var::NamedTuple, ddict)
    Expr(:call, :(>=), toexpr(op.lhs, var, ddict), toexpr(op.rhs, var, ddict))
end

function Base.show(io::IO, x::GreaterThanOrEqual)
    print(io, "GreaterThanOrEqual(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct LessThan <: BoolExpr #? Use `<` operator.
    lhs::Any
    rhs::Any
end

function toexpr(op::LessThan, var::NamedTuple, ddict)
    Expr(:call, :(<), toexpr(op.lhs, var, ddict), toexpr(op.rhs, var), ddict)
end

function Base.show(io::IO, x::LessThan)
    print(io, "LessThan(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct LessThanOrEqual <: BoolExpr #? Use `<=` operator.
    lhs::Any
    rhs::Any
end

function toexpr(op::LessThanOrEqual, var::NamedTuple, ddict)
    Expr(:call, :(<=), toexpr(op.lhs, var, ddict), toexpr(op.rhs, var), ddict)
end

function Base.show(io::IO, x::LessThanOrEqual)
    print(io, "LessThanOrEqual(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct Modulo <: PnmlExpr #? Use `mod` operator.
    lhs::Any
    rhs::Any
end

expr_sortref(a::Modulo; ddict) = sortref(a.lhs)::AbstractSortRef

function toexpr(op::Modulo, var::NamedTuple, ddict)
    Expr(:call, :mod, toexpr(op.lhs, var, ddict), toexpr(op.rhs, var, ddict))
end

function Base.show(io::IO, x::Modulo)
    print(io, "Modulo(", x.lhs, ", ", x.rhs, ")" )
end


#& Partition
# PartitionElement is an operator declaration. Is this a literal? See PartitionElementOf.
@matchable struct PartitionElementOp <: OpExpr #! Same as PartitionElement, for term rerwite?
    id::Symbol
    name::Union{String,SubString{String}}
    refs::Vector{REFID} # to FEConstant
    partition::REFID
end

expr_sortref(a::PartitionElementOp; ddict) = sortref(partitionsort(ddict, a.partition))::AbstractSortRef

toexpr(op::PartitionElementOp, var::NamedTuple, ddict) = error("implement me ", repr(op))
#! Expr(:call, :(||), toexpr(op.lhs, var), toexpr(op.rhs, var))

function Base.show(io::IO, x::PartitionElementOp)
    print(io, "PartitionElementOp(", x.id, ", ", x.name, ", ", x.refs, ")" )
end

#> comparison functions on the partition elements which is based on
#> the order in which they occur in the declaration of the partition
@matchable struct PartitionLessThan <: BoolExpr
    lhs::Any #PartitionElement
    rhs::Any #PartitionElement
end

function ltp_impl(lhs, rhs)
    #@warn "ltp_impl" lhs  rhs
    lhs < rhs
end

toexpr(op::PartitionLessThan, var::NamedTuple, ddict) = error("implement me ", repr(op))
#! Expr(:call, :(||), toexpr(op.lhs, var), toexpr(op.rhs, var))

function Base.show(io::IO, x::PartitionLessThan)
    print(io, "PartitionLessThan(", x.lhs, ", ", x.rhs, ")" )
end

@matchable struct PartitionGreaterThan <: BoolExpr
    lhs::Any #PartitionElement
    rhs::Any #PartitionElement
    # return BoolExpr
end

function gtp_impl(lhs, rhs)
    #@warn "gtp_impl" lhs  rhs
    lhs > rhs
end

function toexpr(op::PartitionGreaterThan, varsub::NamedTuple, ddict)
    #@warn "toexpr PartitionGreaterThan" op varsub
    Expr(:call, gtp_impl, toexpr(op.lhs, varsub, ddict), toexpr(op.rhs, varsub, ddict))
end
#! Expr(:call, :(||), toexpr(op.lhs, var), toexpr(op.rhs, var))

function Base.show(io::IO, x::PartitionGreaterThan)
    print(io, "PartitionGreaterThan(", x.lhs, ", ", x.rhs, ")" )
end

# 0-arity despite the refpartition
@matchable struct PartitionElementOf <: PnmlExpr
    arg::Any
    refpartition::REFID # TODO! SortRef
end

expr_sortref(a::PartitionElementOf; ddict) = sortref(partitionsort(ddict, a.refpartition))::AbstractSortRef

function _peo_impl(fec::FEConstant, refpart, ddict)
    #@warn "peo_impl" lhs refpart
    p = partitionsort(ddict, refpart)
    # look for value of fec in findfirst(e -> PNML.Declarations.contains(e, fec()), p.elements)
    findfirst(Fix2(PNML.Declarations.contains, fec()), p.elements)
end

function toexpr(op::PartitionElementOf, varsub::NamedTuple, ddict)
    #@warn "toexpr PartitionElementOf" op varsub
    Expr(:call, _peo_impl, toexpr(op.arg, varsub, ddict), QuoteNode(op.refpartition), ddict)
end
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

@matchable struct StringLessThan{T <: AbstractString} <: BoolExpr
    lhs::T
    rhs::T
    # use ?
end

@matchable struct StringLessThanOrEqual{T <: AbstractString} <: BoolExpr
    lhs::T
    rhs::T
    # use ?
end

@matchable struct StringGreaterThan{T <: AbstractString} <: BoolExpr
    lhs::T
    rhs::T
    # use ?
end

@matchable struct StringGreaterThanOrEqual{T <: AbstractString} <: BoolExpr
    lhs::T
    rhs::T
    # use ?
end

@matchable struct SubstringEx{T <: AbstractString} <: PnmlExpr
    str::T
    start::Int
    length::Int
    # use ?
end


#&=========================================================================================
#& Lists

#
@matchable struct ListEx{T <: AbstractSortRef} <: PnmlExpr
    basis::T
    els::Vector{Any} #
end

function toexpr(op::ListEx, varsub::NamedTuple, ddict)
    #@warn "toexpr ListEx" op varsub
    els = [eval(toexpr(arg, varsub, ddict)) for arg in op.els]
    Expr(:vect, els...)
end

function Base.show(io::IO, x::ListEx)
    print(io, "ListEx(", x.basis, ", ", x.els, ")" )
end



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

`PnmlTupleEx` `TermInterface` expression object wraps an ordered collection of `PnmlExpr` objects.
There is a related `ProductSort`: an ordered collection of sorts.
Each tuple element will have the same sort as the corresponding product sort.

NB: ISO 15909 Standard considers Tuple to be an Operator.
"""
PnmlTupleEx

@matchable struct PnmlTupleEx <: PnmlExpr #{N, T<:PnmlExpr}
    args::Vector{Any} # >=2 subterms
end

# <tuple> is an operator.
# The sort of a tuple is a tuple of its element's sorts (a.k.a ProductSort).
# Find the ProductSortRef
function expr_sortref(tup::PnmlTupleEx; ddict)
    exsort = ProductSort(tuple(expr_sortref.(tup.args; ddict)...), ddict)
    for (sortid,ps) in pairs(PNML.productsorts(ddict))
        #!@show ps
        if length(exsort) == length(ps) && PNML.Sorts.equalSorts(exsort, ps)
            return ProductSortRef(sortid)
        end
    end
    error("no productsort for tuple expression $(tup)")
end

function toexpr(op::PnmlTupleEx, varsub::NamedTuple, ddict)
    @assert length(op.args) >= 2
    # @warn("toexpr PnmlTupleEx", op.args, varsub,
    #         toexpr.(op.args, Ref(varsub)),
    #         (eval ∘ toexpr).(op.args, Ref(varsub)),)
    #~ Must allow for mixed constant (0-ary operator) and variable expressions.
    #? Do input arc inscriptions ever have constant expressions?
    #* Defaults for example.
    #! Start by assuming tuples are either all constants or all variables.
    # foreach(Fix2(getproperty, :refid), op.args)
    # Extract tuple of sort REFIDs from expressions.  Map to ProductSort

    # @show psorts = tuple((expr_sortref.(op.args, ddict))...)
    # args = if all(Fix2(isa, Symbol), op.args)
    #     map(vexp -> feconstant(vexp.refid), op.args)

    args = op.args
    # if all(Fix2(isa, VariableEx), op.args)
    #     # toexpr is to QuoteNode holding REFID.
    #     map(vexp -> feconstant(vexp.refid), op.args)
    # else
    #     op.args
    # end
    # @show args
    # PnmlTuple{psorts}(x...)
    Expr(:call, tuple, toexpr.(args, Ref(varsub), Ref(ddict))...)
end

# #? Would this be a candidate for rewriting?
# _deref_variable(v::Any) = identity(v) # Bet that it is an operator  expression -> FEConstant!
# _deref_variable(vexp::VariableEx) = feconstant(ddict, vexp.refid)

function Base.show(io::IO, x::PnmlTupleEx)
    print(io, "PnmlTuplEx(", x.args, ")" )
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
toexpr(exp::LiteralExpr, varsub::NamedTuple, ddict) = recurse_expr(exp.ex, varsub, ddict)

"""
    substitute(expr, dict)

Recursivly substitute a VariableEx with its the value from `dict`.
The values in `dict` will be ground terms of a place's sorttype.
These values are from the current marking vector.
```
"""
function substitute(expr::PnmlExpr, var::NamedTuple)
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
end # module Expressons
