####################################################################################
##! add *MORE* TermInteface here
####################################################################################

value(op::AbstractOperator) = error("value not defined for $(typeof(op))")

"return output sort of operator"
sortof(op::AbstractOperator) = error("sortof not defined for $(typeof(op))")

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
"""
Tuple in many-sorted algebra AST.Bool, Int, Float64, XDVT
"""
struct PnmlTuple <: AbstractOperator end

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
    ids::Tuple # decldict(first(ids)) is where the NamedOperator lives.
end
UserOperator(str::AbstractString, ids::Tuple) = UserOperator(Symbol(str), ids)
netid(uo::UserOperator) = first(uo.ids)

function (uo::UserOperator)(#= pass arguments to operator =#)
    println("UserOperator functor $(netid(uo)) $(uo.declaration)")
    @show uo decldict(netid(uo))
    #! FEConstants are 0-ary operators. namedoperators?
    if isempty(decldict(netid(uo)).namedoperators)
        @warn "useroperator found no named operators for $uo. returning false"
        return false
    else
        @show has_named_op(decldict(netid(uo)), uo.declaration)
        no = named_op(decldict(netid(uo)), uo.declaration)
        no(#= pass arguments to operator =#)
    end
end

sortof(uo::UserOperator) = sortof(named_op(decldict(netid(uo)), uo.declaration))
