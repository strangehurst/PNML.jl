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
netid(op::AbstractOperator) = hasproperty(op, :ids) ? netid(op.ids) : error("$(typeof(op)) missing id stuple")

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
#!    symtype(expr)

:(arr[i, j]) == maketerm(Expr, :ref, [:arr, :i, :j]) #~ varaible? what does arr[] mean here?
:(f(a, b))   == maketerm(Expr, :call, [:f, :a, :b])  #~ operator

:(f()) == maketerm(Expr, :call, [:f])  #~ Operator is possibly a constant when 0-ary Callable (which the compiler may optimizie)

variables: store in dictionary named "variables", key is PNML ID: maketerm(Expr, :ref, [:variables, :pid])

===================================#

# Two levels of predicate. Is it an expression, then is it *also* callable.
TermInterface.isexpr(op::AbstractOperator)    = false
TermInterface.iscall(op::AbstractOperator)    = false # users promise that this is only called if isexpr is true.
TermInterface.head(op::AbstractOperator)      = error("NOT IMPLEMENTED: $(typeof(op))")
TermInterface.children(op::AbstractOperator)  = error("NOT IMPLEMENTED: $(typeof(op))")
TermInterface.operation(op::AbstractOperator) = error("NOT IMPLEMENTED: $(typeof(op))")
TermInterface.arguments(op::AbstractOperator) = error("NOT IMPLEMENTED: $(typeof(op))")
TermInterface.arity(op::AbstractOperator)     = error("NOT IMPLEMENTED: $(typeof(op))")
TermInterface.metadata(op::AbstractOperator)  = error("NOT IMPLEMENTED: $(typeof(op))")

"""
Operator as Functor

tag maps to func, a functor/function Callable. Its arity is same as length of inexprs and insorts
"""
struct Operator <: AbstractOperator
    tag::Symbol
    func::Function # Apply `func` to `inexprs`: evaluated with current variable values and constants.
    inexprs::Vector{AbstractTerm} # typeof(inexprs[i]) == eltype(insorts[i])
    insorts::Vector{AbstractSort} #
    outsort::Any #! AbstractSort
    #TODO have constructor validate typeof(inexprs[i]) == eltype(insorts[i])
    #=
    all((ex,so) -> typeof(ex) == eltype(so), zip(inexprs, insorts))
    =#
end

tag(op::Operator)    = op.tag
sortof(op::Operator) = op.outsort
inputs(op::Operator) = op.inexprs
basis(op::Operator)  = basis(sortof(op))

function (op::Operator)()
    println("\nOperator functor $(tag(op)) arity $(arity(op)) $(sortof(op))")
    input = [x() for x in inputs(op)] # evaluate each AbstractTerm
    #@show typeof.(input) op.insorts eltype.(op.insorts)
    #@assert sortof.(input) == op.insorts #"expect two vectors that are pairwise equalSorts"
    out = op.func(input)
    #@show isa(out, eltype(sortof(op))) #! should be assert
    return out
end

value(op::Operator)     = _evaluate(op)
_evaluate(op::Operator) = op() #TODO
arity(op::Operator)     = length(inputs(op))

TermInterface.isexpr(op::Operator)    = false
TermInterface.iscall(op::Operator)    = false # users promise that this is only called if isexpr is true.
TermInterface.head(op::Operator)      = etag(op)
TermInterface.children(op::Operator)  = error("NOT IMPLEMENTED: $(typeof(op))")
TermInterface.operation(op::Operator) = op.func
TermInterface.arguments(op::Operator) = inputs(op)
TermInterface.arity(op::Operator)     = arity(op)
TermInterface.metadata(op::Operator)  = error("NOT IMPLEMENTED: $(typeof(op))")

function Base.show(io::IO, t::Operator)
    print(io, nameof(typeof(t)), "(")
    show(io, tag(t)); print(io, ", ");
    show(io, sortof(t)); print(io, ", ");
    show(io, inputs(t))
    print(io, ")")
end


#-----------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------
boolean_operators = (:or,
                     :and,
                     :not,
                     :imply,
                     :equality,
                     :inequality,
                    )
isbooleanoperator(tag::Symbol) = tag in boolean_operators
# boolean constants true, false

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


# these constants are operators
builtin_constants = (:numberconstant,
                     :dotconstant,
                     :booleanconstant,
                     )

isbuiltinoperator(tag::Symbol) = tag in builtin_operators

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
#===============================================================#


"Dummy function"
function null_function(inputs)#::Vector{AbstractTerm})
    println("NULL_FUNCTION: ", inputs)
end

# Boolean Built-in Operators
#-----------------------------
function builtin_or(inputs)#::Vector{AbstractTerm})
    println("builtin_or: ", inputs)
    return false #! Lie until we know how! XXX
end
function builtin_and(inputs)#::Vector{AbstractTerm})
    println("builtin_and: ", inputs)
    return false #! Lie until we know how! XXX
end
function builtin_not(inputs)#::Vector{AbstractTerm})
    println("builtin_not: ", inputs)
    return false #! Lie until we know how! XXX
end

function builtin_imply(inputs)#::Vector{AbstractTerm})
    println("builtin_imply: ", inputs)
    return false #! Lie until we know how! XXX
end
function builtin_equality(inputs)#::Vector{AbstractTerm})
    println("builtin_equality: ", inputs)
    return false #! Lie until we know how! XXX
end
function builtin_inequality(inputs)#::Vector{AbstractTerm})
    println("builtin_inequality: ", inputs)
    return false #! Lie until we know how! XXX
end

# Integer Built-in Operators
#-----------------------------:
function builtin_addition(inputs) # "Addition",
    println("builtin_addition: ", inputs)
    return false #! Lie until we know how! XXX
end
function builtin_subtraction(inputs) # "Subtraction",
    println("builtin_subtraction: ", inputs)
    return false #! Lie until we know how! XXX
end
function builtin_mult(inputs) # "Multiplication",
    println("builtin_mult: ", inputs)
    return false #! Lie until we know how! XXX
end
function builtin_div(inputs) # "Division",
    println("builtin_div: ", inputs)
    return false #! Lie until we know how! XXX
end
function builtin_mod(inputs) # "Modulo",
    println("builtin_mod: ", inputs)
    return false #! Lie until we know how! XXX
end
function builtin_gt(inputs) # "GreaterThan",
    println("builtin_gt: ", inputs)
    return false #! Lie until we know how! XXX
end
function builtin_geq(inputs) # "GreaterThanOrEqual",
    println("builtin_geq: ", inputs)
    return false #! Lie until we know how! XXX
end
function builtin_lt(inputs) # "LessThan",
    println("builtin_lt: ", inputs)
    return false #! Lie until we know how! XXX
end
function builtin_leq(inputs) # "LessThanOrEqual",)
    println("builtin_leq: ", inputs)
    return false #! Lie until we know how! XXX
end

# Multiset Built-in Operators
#-----------------------------
function builtin_add(inputs)
    println("builtin_all: ", inputs)
    return false #! Lie until we know how! XXX
end
function builtin_all(inputs)
    println("builtin_all: ", inputs)
    return false #! Lie until we know how! XXX
end
function builtin_numberof(inputs)
    println("builtin_numberof: ", inputs)
    return false #! Lie until we know how! XXX
end
function builtin_subtract(inputs)
    println("builtin_subtract: ", inputs)
    return false #! Lie until we know how! XXX
end
function builtin_scalarproduct(inputs)
    println("builtin_scalarproduct: ", inputs)
    return false #! Lie until we know how! XXX
end
function builtin_empty(inputs)
    println("builtin_empty: ", inputs)
    return false #! Lie until we know how! XXX
end
function builtin_cardnality(inputs)
    println("builtin_cardnality: ", inputs)
    return false #! Lie until we know how! XXX
end
function builtin_cardnalitiyof(inputs)
    println("builtin_cardnalitiyof: ", inputs)
    return false #! Lie until we know how! XXX
end
function builtin_contains(inputs)
    println("builtin_contains: ", inputs)
    return false #! Lie until we know how! XXX
end

# Finite Enumeration Built-in Operators
#-----------------------------
function builtin_lessthan(inputs)
    println("builtin_lessthan: ", inputs)
    return false #! Lie until we know how! XXX
end
function builtin_lessthanorequal(inputs)
    println("builtin_lessthanorequal: ", inputs)
    return false #! Lie until we know how! XXX
end
function builtin_greaterthan(inputs)
    println("builtin_greaterthan: ", inputs)
    return false #! Lie until we know how! XXX
end
function builtin_greaterthanorequal(inputs)
    println("builtin_greaterthanorequal: ", inputs)
    return false #! Lie until we know how! XXX
end
function builtin_finiteintrangeconstant(inputs)
    println("builtin_finiteintrangeconstant: ", inputs)
    return false #! Lie until we know how! XXX
end

# Partition Built-in Operators
#-----------------------------
function builtin_ltp(inputs)
    println("builtin_ltp: ", inputs)
    return false #! Lie until we know how! XXX
end
function builtin_gtp(inputs)
    println("builtin_gtp: ", inputs)
    return false #! Lie until we know how! XXX
end
function builtin_partitionelementof(inputs)
    println("builtin_partitionelementof: ", inputs)
    return false #! Lie until we know how! XXX
end

#  Constant Built-in Operators
#-----------------------------
function builtin_numberconstant(inputs)
    println("builtin_numberconstant: ", inputs)
    return false #! Lie until we know how! XXX
end
function builtin_dotconstant(inputs)
    println("builtin_:dotconstant ", inputs)
    return false #! Lie until we know how! XXX
end
function builtin_booleanconstant(inputs)
    println("builtin_booleanconstant: ", inputs)
    return false #! Lie until we know how! XXX
end

#-----------------------------
function builtin_tuple(inputs)
    println("builtin_tuple: ", inputs)
    return false #! Lie until we know how! XXX
end


#---------------------------------------------------------------------
"""
    hl_operators[Symbol] -> Function, Sort

Map PNML operation ID to a tuple of function that accepts a single vector of arguments
and the sort of the result. See [`pnml_hl_operator`](@ref)
"""
const hl_operators = Dict(
    :or => builtin_or,
    :and => builtin_and,
    :not => builtin_not,
    :imply => builtin_imply,
    :equality => builtin_equality,
    :inequality => builtin_inequality,

    :addition => builtin_addition,
    :subtraction => builtin_subtraction,
    :mult => builtin_mult,
    :div => builtin_div,
    :mod => builtin_mod,
    :gt => builtin_gt,
    :geq => builtin_geq,
    :lt => builtin_lt,
    :leq => builtin_leq,

    :add => builtin_add,
    :all => builtin_all,
    :numberof => builtin_numberof,
    :subtract => builtin_subtract,
    :scalarproduct => builtin_scalarproduct,
    :empty => builtin_empty, #! return empty multiset with given basis sort
    :cardnality => builtin_cardnality,
    :cardnalitiyof => builtin_cardnalitiyof,
    :contains => builtin_contains,

    :lessthan => builtin_lessthan,
    :lessthanorequal => builtin_lessthanorequal,
    :greaterthan => builtin_greaterthan,
    :greaterthanorequal => builtin_greaterthanorequal,
    :finiteintrangeconstant => builtin_finiteintrangeconstant,

    :ltp => builtin_ltp,
    :gtp => builtin_gtp,
    :partitionelementof => builtin_partitionelementof,

    :tuple => builtin_tuple,
    #:numberconstant => builtin_,
    #:dotconstant => builtin_,
    #:booleanconstant => builtin_,
)

"""
    pnml_hl_operator(tag::Symbol) -> Callable(::Vector{AbstractTerm})

Return callable with a single argument, a vector of inputs.
"""
function pnml_hl_operator(tag::Symbol)
    if haskey(hl_operators, tag)
        return hl_operators[tag]
    else
        @error "$tag is not a known hl_operator, return null_function"
        return null_function #, NullSort()
    end
end

"""
    pnml_hl_outsort(tag::Symbol; insorts::Vector{AbstractSort}, ids::Tuple) -> Sort

Return sort that builtin operator returns.
"""
function pnml_hl_outsort(tag::Symbol; insorts::Vector{AbstractSort}, ids::Tuple)
    if isbooleanoperator(tag)
        BoolSort()
    elseif isintegeroperator(tag)
        IntegerSort()
    elseif ismultisetoperator(tag)
        if tag in (:add,)
            length(insorts) >= 2 ||
                @error "pnml_hl_outsort length(insorts) < 2" tag insorts
            multisetsort(basis(last(insorts))) # is it always last?
        elseif tag in(:all, :numberof, :subtract, :scalarproduct)
            length(insorts) == 2 ||
                @error "pnml_hl_outsort length(insorts) != 2" tag insorts
            multisetsort(basis(last(insorts))) # is it always last?
        elseif tag === :empty # a constant
            length(insorts) == 1 ||
                @error "pnml_hl_outsort length(insorts) != 1" tag insorts
            multisetsort(basis(first(insorts)))
        elseif tag === :cardnality
            NaturalSort()
        elseif tag === :cardnalitiyof
            NaturalSort()
        elseif tag === :contains
            BoolSort()
        else
            error("$tag not a known multiset operator")
        end
    elseif isfiniteoperator(tag)
        #:lessthan, :lessthanorequal, :greaterthan, :greaterthanorequal, :finiteintrangeconstant
        @error("enumeration sort needs content, ids")
        FiniteEnumerationSort((); ids) #! pnml_hl_outsort will need FEC reference tuple, ids
        #
    elseif ispartitionoperator(tag)
        #:ltp, :gtp, :partitionelementof
        PartitionSort() #! pnml_hl_outsort will need content
    elseif tag === :tuple
        @warn "pnml_hl_outsort does not handle tuple yet"
        TupleSort()  #! pnml_hl_outsort will need content?
        #:numberconstant => NumberSort(),
        #:dotconstant => DotSort(),
        #:booleanconstant => BoolSort(),
    else
         @error "$tag is not a known to pnml_hl_outsort, return NullSort()"
        return NullSort()
    end
end

#===============================================================#
#===============================================================#
# """
# Tuple in many-sorted algebra AST.Bool, Int, Float64, XDVT
# """
# struct PnmlTuple <: AbstractOperator end
#===============================================================#

"""
    pnmlmultiset(x::T, basis::AbstractSort, multi::Integer=1; ids::Tuple) -> PnmlMultiset{T,S}

Construct as a multiset with one element, `x`, with default multiplicity of 1.

PnmlMultiset wraps a Multisets.Multiset{T} and basis sort S.

Some [`Operators`](@ref)` and [`Variables`](@ref) create/use a multiset.
Thre are constants defined that must be multisets since HL markings are multisets.

multi`x
"""
struct PnmlMultiset{T, S<:AbstractSort} <: AbstractOperator
    basis::S # UserSort that References id of sort declaration.
    mset::Multiset{T} #,
end

Base.zero(::Type{PnmlMultiset{T, S}}) where{T, S<:AbstractSort} = zero(Int)
Base.one(::Type{PnmlMultiset{T, S}}) where{T, S<:AbstractSort} = one(Int)


function Base.show(io::IO, t::PnmlMultiset{<:Any, <:AbstractSort})
    print(io, nameof(typeof(t)), "(basis=", repr(basis(t)))
    print(io, ", mset=", nameof(typeof(t.mset)), "(",)
    io = inc_indent(io)
    for (k,v) in pairs(t.mset)
        println(io, repr(k), " => ", repr(v), ",")
    end
    print(io, "))") # Close BOTH parens.
end


"""
    pnmlmultiset(x, basis::AbstractSort, multi::Integer=1)

Constructs a [`PnmlMultiset`](@ref)` containing multiset "1'x" and a sort.

Any `x` that supports `sortof(x)`
"""
function pnmlmultiset(x, basis::AbstractSort, multi::Integer=1)
    # has_sort(x) ||
    #     throw(ArgumentError("x::$(typeof(x)) does not have a sort"))
    if !isa(x, Number) && isa(sortof(x), MultisetSort)
        throw(ArgumentError("sortof(x) cannot be a MultisetSort: found $(sortof(x))"))
    end
    multi >= 0 ||
        throw(ArgumentError("multiplicity cannot be negative: found $multi"))
    #^ Where/how is absence of sort loop checked?

    #~println("pnmlmultiset(")
    #~@show x basis multi
    # @show typeof(x)
    # @show sortof(x)
    # @show typeof(sortof(x))
    # @show typeof(basis)
    # @show sortof(basis)
    M = Multiset{typeof(x)}()
    #@show typeof(M) eltype(M)
    M[x] = multi #
    #@warn typeof(M) #repr(M)
    #@warn typeof(basis) repr(basis)
    #@warn collect(elements(basis))
    PnmlMultiset(basis, M)
end

sortof(ms::PnmlMultiset{<:Any, <:AbstractSort}) = sortof(basis(ms)) # Dereferences the UserSort

multiplicity(ms::PnmlMultiset{<:Any, <:AbstractSort}, x) = ms.mset[x]
issingletonmultiset(ms::PnmlMultiset{<:Any, <:AbstractSort}) = length(ms.mset) == 1
cardinality(ms::PnmlMultiset{<:Any, <:AbstractSort}) = length(ms.mset)

# TODO forward what ops to Multiset?
# TODO alter Multiset: union, add element, erase element, change multiplicity?

"""
    basis(ms::PnmlMultiset) -> UserSort
Multiset basis sort is a UserSort that references the declaration of a NamedSort.
Which gives a name and id to a built-in Sorts, ProductSorts, or __other__ UserSorts.
MultisetSorts not allowed. Nor loops in sort references.
"""
basis(ms::PnmlMultiset{<:Any, <:AbstractSort}) = ms.basis

elements(ms::PnmlMultiset{<:Any, <:AbstractSort}) = elements(basis(ms))

_evaluate(ms::PnmlMultiset{<:Any, <:AbstractSort}) = cardinality(ms)

"""
$(TYPEDEF)
$(TYPEDFIELDS)

User operators refers to a [`NamedOperator`](@ref) declaration.
"""
struct UserOperator <: AbstractOperator
    declaration::Symbol # of a NamedOperator
    ids::Tuple # decldict(netid(ids)) is where the NamedOperator lives.
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
        @show r  = op(#= pass arguments to functor/operator =#)
        return r
    end
end

sortof(uo::UserOperator) = sortof(operator(decldict(netid(uo)), uo.declaration))
basis(uo::UserOperator) = sortof(uo)
