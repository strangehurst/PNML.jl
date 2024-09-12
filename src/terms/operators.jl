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

# Two levels of predicate. Is it an expression, then is it *also* callable.
# TermInterface.isexpr(op::AbstractOperator)    = false
# TermInterface.iscall(op::AbstractOperator)    = false # users promise that this is only called if isexpr is true.
# TermInterface.head(op::AbstractOperator)      = error("NOT IMPLEMENTED: $(typeof(op))")
# TermInterface.children(op::AbstractOperator)  = error("NOT IMPLEMENTED: $(typeof(op))")
# TermInterface.operation(op::AbstractOperator) = error("NOT IMPLEMENTED: $(typeof(op))")
# TermInterface.arguments(op::AbstractOperator) = error("NOT IMPLEMENTED: $(typeof(op))")
# TermInterface.arity(op::AbstractOperator)     = error("NOT IMPLEMENTED: $(typeof(op))")
# TermInterface.metadata(op::AbstractOperator)  = error("NOT IMPLEMENTED: $(typeof(op))")

"""
Operator as Functor

tag maps to func, a functor/function Callable. Its arity is same as length of inexprs and insorts
"""
struct Operator <: AbstractOperator
    tag::Symbol
    func::Union{Function, Type} # `func` to `inexprs`: evaluated with current variable values and constants.
    inexprs::Vector{AbstractTerm}
    insorts::Vector{UserSort} # typeof(inexprs[i]) == eltype(insorts[i])
    outsort::UserSort # wraps IDREF Symbol
    metadata::Any
    #TODO have constructor validate typeof(inexprs[i]) == eltype(insorts[i])
    #todo all((ex,so) -> typeof(ex) == eltype(so), zip(inexprs, insorts))
end

Operator(t, f, inex, ins, outs; metadata=nothing) = Operator(t, f, inex, ins, outs, metadata)
tag(op::Operator)       = op.tag
sortof(op::Operator)    = sortof(op.outsort)
inputs(op::Operator)    = op.inexprs
basis(op::Operator)     = basis(sortof(op))

value(op::Operator)     = _evaluate(op)       #
_evaluate(op::Operator) = op() #TODO

function (op::Operator)()
    #~ println("\nOperator functor $(tag(op)) arity $(arity(op)) $(sortof(op))")
    input = map(term -> term(), inputs(op)) #^ evaluate each operator or variable
    #@show typeof.(input) op.insorts eltype.(op.insorts)
    @assert all((in,so) -> typeof(in) == eltype(so), zip(input, insorts(op)))
    out = op.func(input) #^ apply func to evaluated +/-inputs
    @assert isa(out, eltype(sortof(op)))
    return out
end


TermInterface.isexpr(op::Operator)    = true
TermInterface.iscall(op::Operator)    = true # users promise that this is only called if isexpr is true.
TermInterface.head(op::Operator)      = tag(op)
TermInterface.children(op::Operator)  = inputs(op)
TermInterface.operation(op::Operator) = op.func
TermInterface.arguments(op::Operator) = inputs(op)
TermInterface.arity(op::Operator)     = length(inputs(op))
TermInterface.metadata(op::Operator)  = nothing

function TermInterface.maketerm(::Type{Operator}, operation, arguments, metadata)
    Operator(iscall, operation, arguments...; metadata)
end

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
    return nothing
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
    :partitionelementof => builtin_partitionelementof, #! partition IDREF as input

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
    pnml_hl_outsort(tag::Symbol; insorts::Vector{UserSort}) -> UserSort

Return sort that operator `tag` returns.
"""
function pnml_hl_outsort(tag::Symbol; insorts::Vector{UserSort})
    #=
    Question? can these ever be built-in sorts? If so, when, why?
    UserSorts are the expected form. This allows mapping id to AbstractSort via NamedSorts.
    NamedSorts are used to wrap built-in sorts (as well as give them an name).
    =#

    if isbooleanoperator(tag) # 0-arity function is a constant
        usersort(:bool) # BoolSort()
    elseif isintegeroperator(tag) # 0-arity function is a constant
        usersort(:integer) # IntegerSort()
    elseif ismultisetoperator(tag)
        if tag in (:add,)
            length(insorts) >= 2 ||
                @error "pnml_hl_outsort length(insorts) < 2" tag insorts
            last(insorts) # is it always last?
            #todo assert is multiset
        elseif tag in(:all, :numberof, :subtract, :scalarproduct)
            length(insorts) == 2 || @error "pnml_hl_outsort length(insorts) != 2" tag insorts
            last(insorts) # is it always last?
        elseif tag === :empty # a "constant" that needs a basis sort
            length(insorts) == 1 || @error "pnml_hl_outsort length(insorts) != 1" tag insorts
            first(insorts)
        elseif tag === :cardnality
            usersorts()[:natural] # NaturalSort()
        elseif tag === :cardnalitiyof
            usersorts()[:natural] # NaturalSort()
        elseif tag === :contains
            usersorts()[:bool] # BoolSort()
        else
            error("$tag not a known multiset operator")
        end
    elseif isfiniteoperator(tag)
        #:lessthan, :lessthanorequal, :greaterthan, :greaterthanorequal, :finiteintrangeconstant
        length(insorts) == 2 || @error "pnml_hl_outsort length(insorts) != 2" tag insorts
        @error("enumeration sort needs content")
        first(insorts)
        #todo assert is finite enumeration
        #
    elseif ispartitionoperator(tag)
        #:ltp, :gtp, :partitionelementof
        length(insorts) == 2 || @error "pnml_hl_outsort length(insorts) != 2" tag insorts
        first(insorts)
        #todo assert is PartitionSort() #! pnml_hl_outsort will need content
    elseif tag === :tuple
        @warn "pnml_hl_outsort does not handle tuple yet"
        length(insorts) == 2 || @error "pnml_hl_outsort length(insorts) != 2" tag insorts
        first(insorts)
        #todo assert   TupleSort()  #! pnml_hl_outsort will need content?
    elseif tag === :numberconstant
        usersort(:integer) #! should be NumberSort()
    elseif tag === :dotconstant
        usersort(:dot)
    elseif tag === :booleanconstant
        usersort(:bool)
    else
         @error "$tag is not a known to pnml_hl_outsort, return NullSort()"
         usersort(:null)
    end
end

#===============================================================#
#===============================================================#
#===============================================================#

"""
$(TYPEDEF)
$(TYPEDFIELDS)

User operators refers to a [`NamedOperator`](@ref) declaration.
"""
struct UserOperator <: AbstractOperator
    declaration::Symbol # of a NamedOperator
end

function (uo::UserOperator)(#= pass arguments to operator =#)
    # println()
    # println()
    #~ println("UserOperator functor $uo")
    # @show uo
    # dd = DECLDICT[]
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

    if !has_operator(uo.declaration)
        @warn "found NO operator $(uo.declaration), returning `false`"
        return false
    else
        op = operator(uo.declaration) # get operator from decldict
        @warn "found operator $(uo.declaration)`"
        r  = op(#= pass arguments to functor/operator =#)
        return r
    end
end

sortof(uo::UserOperator) = sortof(operator(uo.declaration)) # return sortof NamedOperator
basis(uo::UserOperator) = sortof(uo)
