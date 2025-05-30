#=


getSubterm -> list term
getOutput -> sort
getInput -> list sort

getDeclaration

useroperator -> operator declaration -> builtin operator
Let OpExpr <: PnmlExpr

finite element constant is 0-ary operator expressed as useroperator wrapping an REFID

`:(feconstant(REFID)())`
locates the FEConstant element in the DeclDict and return its value/id/name(TBD).
there are 4 kinds of operator declarations:
    feconstant, nameoperator, arbitraryoperator, partitionelement
each have different types.
See decldictcore.jl

sortdefinition(outsort) isa FEConstant, inexprs, insorts are empty.


eval(::FEXEx)
=#
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
    declarationdicts::DeclDict
    #TODO have constructor validate typeof(inexprs[i]) == eltype(insorts[i])
    #todo all((ex,so) -> typeof(ex) == eltype(so), zip(inexprs, insorts))
end

Operator(t, f, inex, ins, outs; metadata=nothing, ddict) = Operator(t, f, inex, ins, outs, metadata, ddict)

decldict(op::Operator) = op.declarationdicts
tag(op::Operator)     = op.tag # PNML XML tag
inputs(op::Operator)  = op.inexprs #! when should these be eval(toexpr)'ed)
sortref(op::Operator) = identity(op.outsort)::UserSort
sortof(op::Operator)  = sortdefinition(namedsort(decldict(op), op.outsort)) # also abstractsort, partitionsort
metadata(op::Operator) = op.metadata
value(op::Operator)   = op(#= parameters? =#)

#? Possible to pass variables at this point? Pass marking vector?
function (op::Operator)(#= parameters? =#)
    #println("\nOperator functor $(tag(op)) arity $(arity(op)) $(sortof(op))") #! debug
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

finite_operators()  = (:lessthan,
                     :lessthanorequal,
                     :greaterthan,
                     :greaterthanorequal,
                     :finiteintrangeconstant,
                     )
"""
    iisfiniteoperator(::Symbol) -> Bool

Is tag in `finite_operators()`?
"""
isfiniteoperator(tag::Symbol) = (tag in finite_operators())

partition_operators = (:ltp, :gtp, :partitionelementof)

ispartitionoperator(tag::Symbol) = tag in partition_operators


# these constants are operators
builtin_constants = (:numberconstant, :dotconstant, :booleanconstant,)

"""
    isbuiltinoperator(::Symbol) -> Bool

Is tag in `builtin_operators()`?
"""
isbuiltinoperator(tag::Symbol) = (tag in builtin_constants()) #todo whrat are these?

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

"""
    pnml_hl_operator(tag::Symbol) -> Callable(::Vector{AbstractTerm})

Return callable with a single argument, a vector of inputs.
"""
function pnml_hl_operator(tag::Symbol)
    # if haskey(hl_operators, tag)
    #     return hl_operators[tag]
    # else
    #     @error "$tag is not a known hl_operator, return null_function"
    #     return null_function
    # end
    return null_function
end

"""
    pnml_hl_outsort(tag::Symbol; insorts::Vector{UserSort}) -> UserSort

Return sort that operator `tag` returns.
"""
function pnml_hl_outsort(tag::Symbol; insorts::Vector{UserSort}, ddict::DeclDict)
    #=
    Question? can these ever be built-in sorts? If so, when, why?
    UserSorts are the expected form. This allows mapping id to AbstractSort via NamedSorts.
    NamedSorts are used to wrap built-in sorts (as well as give them an name).
    =#

    if isbooleanoperator(tag) # 0-arity function is a constant
        usersort(ddict, :bool) # BoolSort()
    elseif isintegeroperator(tag) # 0-arity function is a constant
        usersort(ddict, :integer) # IntegerSort()
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
            usersorts(ddict)[:natural] # NaturalSort()
        elseif tag === :cardnalitiyof
            usersorts(ddict)[:natural] # NaturalSort()
        elseif tag === :contains
            usersorts(ddict)[:bool] # BoolSort()
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
        #todo assert is PartitionSort #! pnml_hl_outsort will need content
    elseif tag === :tuple
        @warn "pnml_hl_outsort does not handle tuple yet"
        length(insorts) == 2 || @error "pnml_hl_outsort length(insorts) != 2" tag insorts
        first(insorts)
    elseif tag === :numberconstant
        usersort(ddict, :integer)
    elseif tag === :dotconstant
        usersort(ddict, :dot)
    elseif tag === :booleanconstant
        usersort(ddict, :bool)
    else
         @error "$tag is not a known to pnml_hl_outsort, return NullSort()"
         usersort(ddict, :null)
    end
end

#===============================================================#
#===============================================================#
#===============================================================#

"""
$(TYPEDEF)
$(TYPEDFIELDS)

User operator wraps a [`REFID`](@ref) to a [`OperatorDeclaration`](@ref).
"""
struct UserOperator <: AbstractOperator
    declaration::REFID # of a NamedOperator, AbstractOperator.
    declarationdicts::DeclDict
end
decldict(uo::UserOperator) = uo.declarationdicts

# Forward to the NamedOperator or AbstractOperator declaration in the DeclDict.
function (uo::UserOperator)(parameters)
    if has_operator(uo.declaration)
        op = operator(decldict(uo), uo.declaration) # Lookup operator in DeclDict.
        r = op(parameters) # Operator objects are functors.
        @warn "found operator for $(uo.declaration)" op r
        return r
    end
    error("found NO operator $(repr(uo.declaration))")
end

sortof(uo::UserOperator) = sortof(operator(decldict(uo), uo.declaration))
basis(uo::UserOperator)  = basis(operator(decldict(uo), uo.declaration))

function Base.show(io::IO, uo::UserOperator)
    print(io, nameof(typeof(uo)), "(", repr(uo.declaration), ")")
end
