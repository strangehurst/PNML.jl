
"""
PNML Operator as Functor

tag maps to func, a functor/function Callable. Its arity is same as length of inexprs and insorts
"""
struct Operator <: AbstractOperator
    tag::Symbol
    func::Union{Function, Type} # Apply `func` to `inexprs`:
    inexprs::Vector{AbstractTerm} #! TermInterface expressions some may be variables (not just ground terms).
    insorts::Vector{UserSort} # typeof(inexprs[i]) == eltype(insorts[i])
    outsort::UserSort # wraps IDREF Symbol -> NamedSort, AbstractSort, PartitionSort
    metadata::Any
    #TODO have constructor validate typeof(inexprs[i]) == eltype(insorts[i])
    #todo all((ex,so) -> typeof(ex) == eltype(so), zip(inexprs, insorts))
end

Operator(t, f, inex, ins, outs; metadata=nothing) = Operator(t, f, inex, ins, outs, metadata)
tag(op::Operator)       = op.tag # PNML XML tag
inputs(op::Operator)    = op.inexprs #! when should these be eval(toexpr)'ed)
sortref(op::Operator)   = op.outsort # also abstractsort, partitionsort
sortof(op::Operator)    = sortdefinition(namedsort(op.outsort)) # also abstractsort, partitionsort
metadata(op::Operator)  = op.metadata

value(op::Operator)     = _evaluate(op)       #
_evaluate(op::Operator) = op() #TODO term rewrite

#? Possible to pass variables at this point? Pass marking vector?
function (op::Operator)() #! after term rewrite _evaluate
    println("\nOperator functor $(tag(op)) arity $(arity(op)) $(sortof(op))")
    input = map(term -> term(), inputs(op)) #^ evaluate each operator or variable

    @assert all((in,so) -> typeof(in) == eltype(so), zip(input, insorts(op)))
    out = op.func(input) #^ apply func to evaluated +/-inputs
    @assert isa(out, eltype(sortof(op)))
    return out
end

# Like Metatheory.@matchable
TermInterface.isexpr(op::Operator)    = true
TermInterface.iscall(op::Operator)    = true
TermInterface.head(op::Operator)      = Operator #! A constructor
TermInterface.operation(op::Operator) = TermInterface.head(op)
#!TermInterface.children(op::Operator)  = nothing #getfield.((op,), ($(QuoteNode.(fields)...),))
TermInterface.arguments(op::Operator) = TermInterface.children(op)
TermInterface.arity(op::Operator)     = length(inputs(op))
TermInterface.metadata(op::Operator)  = metadata(op)

#!TermInterface.arity(x::$name) = $(length(fields))

# maketerm is used to rewrite terms of the inexprs.
function TermInterface.maketerm(::Type{Operator}, head, children, metadata)
    head(children...)
end


#=
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
=#

function Base.show(io::IO, t::Operator)
    print(io, nameof(typeof(t)), "(")
    show(io, tag(t)); print(io, ", ");
    show(io, sortof(t)); print(io, ", ");
    show(io, inputs(t))
    print(io, ")")
end

##############################################################
##############################################################

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

#---------------------------------------------------------------------
# """
#     hl_operators[Symbol] -> Function, Sort

# Map PNML operation ID to a tuple of function that accepts a single vector of arguments
# and the sort of the result. See [`pnml_hl_operator`](@ref)
# """
# const hl_operators = Dict(
#     :or => builtin_or,
#     :and => builtin_and,
#     :not => builtin_not,
#     :imply => builtin_imply,
#     :equality => builtin_equality,
#     :inequality => builtin_inequality,

#     :addition => builtin_addition,
#     :subtraction => builtin_subtraction,
#     :mult => builtin_mult,
#     :div => builtin_div,
#     :mod => builtin_mod,
#     :gt => builtin_gt,
#     :geq => builtin_geq,
#     :lt => builtin_lt,
#     :leq => builtin_leq,

#     :add => builtin_add,
#     :all => builtin_all,
#     :numberof => builtin_numberof,
#     :subtract => builtin_subtract,
#     :scalarproduct => builtin_scalarproduct,
#     :empty => builtin_empty, #! return empty multiset with given basis sort
#     :cardnality => builtin_cardnality,
#     :cardnalitiyof => builtin_cardnalitiyof,
#     :contains => builtin_contains,

#     :lessthan => builtin_lessthan,
#     :lessthanorequal => builtin_lessthanorequal,
#     :greaterthan => builtin_greaterthan,
#     :greaterthanorequal => builtin_greaterthanorequal,
#     :finiteintrangeconstant => builtin_finiteintrangeconstant,

#     :ltp => builtin_ltp,
#     :gtp => builtin_gtp,
#     :partitionelementof => builtin_partitionelementof, #! partition IDREF as input

#     :tuple => builtin_tuple,
#     #:numberconstant => builtin_,
#     #:dotconstant => builtin_,
#     #:booleanconstant => builtin_,
# )

"""
    pnml_hl_operator(tag::Symbol) -> Callable(::Vector{AbstractTerm})

Return callable with a single argument, a vector of inputs.
"""
function pnml_hl_operator(tag::Symbol)
    # if haskey(hl_operators, tag)
    #     return hl_operators[tag]
    # else
    #     @error "$tag is not a known hl_operator, return null_function"
    #     return null_function #, NullSort()
    # end
    return null_function #, NullSort()
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
    declaration::REFID # of a NamedOperator
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

sortof(uo::UserOperator) = sortof(operator(uo.declaration)) # return sortof NamedOperator or AbstractOperator
basis(uo::UserOperator) = sortof(uo)
