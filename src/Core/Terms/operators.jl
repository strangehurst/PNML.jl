####################################################################################
##! add *MORE* TermInteface here
####################################################################################
function Base.getproperty(op::AbstractOperator)
    prop_name === :ids && return getfield(op, :ids)::Tuple
    return getfield(sort, prop_name)
end

value(op::AbstractOperator) = error("value not defined for $(typeof(op))")

"Return output sort of operator."
sortof(op::AbstractOperator) = error("sortof not defined for $(typeof(op))")
"Return network id of operator."
netid(op::AbstractOperator) = hasproperty(op, :ids) ? first(op.ids) : error("$(typeof(op)) missing id stuple")

#==================================
 TermInterface version 0.4
    isexpr(x::T) # expression tree (S-expression) => head(x), children(x) required
    iscall(x::T) # call expression => operation(x), arguments(x) required
    head(x) # of S-expression
    children(x) # of S-expression
    operation(x) # if iscall(x)
    arguments(x) # if iscall(x)
    maketerm(T, head, children, type=nothing, metadata=nothing) # iff isexpr(x)
 Optional
    arity(x)
    metadata(x)
    symtype(expr)

:(arr[i, j]) == maketerm(Expr, :ref, [:arr, :i, :j]) #~ varaible? what does arr[] mean here?
:(f(a, b))   == maketerm(Expr, :call, [:f, :a, :b])  #~ operator

:(f()) == maketerm(Expr, :call, [:f])  #~ Operator is possibly a constant when 0-ary Callable (which the compiler may optimizie)

variables: store in dictionary named "variables", key is PNML ID: maketerm(Expr, :ref, [:variables, :pid])

===================================#

# Two levels of predicate. Is it an expression, then is it *also* callable.
TermInterface.isexpr(op::AbstractOperator)  = false
TermInterface.iscall(op::AbstractOperator)  = false # users promise that this is only called if isexpr is true.

TermInterface.head(op::AbstractOperator)      = error("NOT IMPLEMENTED: $(typeof(op))")
TermInterface.children(op::AbstractOperator)  = error("NOT IMPLEMENTED: $(typeof(op))")
TermInterface.operation(op::AbstractOperator) = error("NOT IMPLEMENTED: $(typeof(op))")
TermInterface.arguments(op::AbstractOperator) = error("NOT IMPLEMENTED: $(typeof(op))")

"Constants have arity of 0. Implicit value is size(arguments)"
TermInterface.arity(op::AbstractOperator) = 0
TermInterface.metadata(op::AbstractOperator) = error("NOT IMPLEMENTED: $(typeof(op))")
TermInterface.symtype(op::AbstractOperator)  = error("NOT IMPLEMENTED: $(typeof(op))")

"""
Operator as Functor

tag maps to func, a functor/function Callable. Its arity is sane as length of inexprs and insorts
"""
struct Operator <: AbstractOperator
    tag::Symbol
    func::Function # Apply `func` to `in`: expressions evaluated with current variable values and constants.
    inexprs::Vector{AbstractTerm} # typeof(inexprs[i]) == eltype(insorts[i])
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
    println("\nOperator functor $(tag(op)) arity $(arity(op)) $(sortof(op))")
    @show input = [x() for x in inputs(op)] # evaluate each AbstractTerm
    @show typeof.(input) op.insorts eltype.(op.insorts)
    #@assert sortof.(input) == op.insorts #"expect two vectors that are pairwise equalSorts"
    @show out = op.func(input)
    @show isa(out, eltype(sortof(op))) #! should be assert
    return out
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

partition_operators = (:ltp, :gtp, :partitionelementof)

ispartitionoperator(tag::Symbol) = tag in partition_operators

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

Note: It is not the same as Meta.isoperator. Both work on Symbols. Not expecting any conflict.

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
                          ispartitionoperator(tag) ||
                          tag in builtin_constants ||
                          tag === :tuple ||
                          tag === :useroperator


#===============================================================#


"""
Tuple in many-sorted algebra AST.Bool, Int, Float64, XDVT
"""
struct PnmlTuple <: AbstractOperator end

"""
Some [`Operators`](@ref)` and [`Variables`](@ref) creates/use a multiset.
Wrap a Multisets.Multiset

multi`x where x is an instance of a sort T.
"""
struct PnmlMultiset{T<:AbstractSort} <: AbstractOperator
    x::T # Instance of basis sort. Sorts are NOT all singletons.
    ms::Multiset{T} #
end
PnmlMultiset(multi::Integer, x::AbstractSort) = begin
    @show M = Multiset{typeof(x)}()
    @show multi x typeof(x) sortof(x) typeof(sortof(x)) typeof(M)
    M[x] = multi
    PnmlMultiset(x, M)
end
sortof(ms::PnmlMultiset) = sortof(ms.x)
# TODO forward ops?

"""
$(TYPEDEF)
$(TYPEDFIELDS)

User operators refers to a [`NamedOperator`](@ref) declaration.
"""
struct UserOperator <: AbstractOperator
    declaration::Symbol # of a NamedOperator
    ids::Tuple # decldict(first(ids)) is where the NamedOperator lives.
end
UserOperator(str::AbstractString, ids::Tuple) = UserOperator(Symbol(str), ids)

function (uo::UserOperator)(#= pass arguments to operator =#)
    # println()
    # println()
    println("UserOperator functor $uo")
    # @show uo
    # dd = decldict(netid(uo))
    # @show _op_dictionaries()
    # for op in _op_dictionaries()
    #     @show op getfield(dd, op)
    # end
    # println()
    # _ops(dd)
    # println()
    # operators(dd)
    # println()
    #! FEConstants are 0-ary operators. namedoperators?

    if !has_operator(decldict(netid(uo)), uo.declaration)
        @warn "found no operator $(uo.declaration), returning `false`"
        return false
    else
        @show op = operator(decldict(netid(uo)), uo.declaration)
        @show r =  op(#= pass arguments to functor/operator =#)
        return r
    end
end

sortof(uo::UserOperator) = sortof(operator(decldict(netid(uo)), uo.declaration))
