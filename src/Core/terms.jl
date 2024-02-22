####################################################################################
#
####################################################################################

"""
$(TYPEDEF)
Terms are part of the multi-sorted algebra that is part of a High-Level Petri Net.

An abstract type in the pnml XML specification, concrete `Term`s are
found within the <structure> element of a label.

Notably, a [`Term`](@ref) is not a PnmlLabel (or a PNML Label).

See also [`Declaration`](@ref), [`SortType`](@ref), [`AbstractDeclaration`](@ref).
"""
abstract type AbstractTerm end

_evaluate(x::AbstractTerm) = x() # functor

"""
$(TYPEDEF)
Part of the high-level pnml many-sorted algebra.

> ...can be a built-in constant or a built-in operator, a multiset operator which among others
> can construct a multiset from an enumeration of its elements, or a tuple operator.
> Each operator has a sequence of sorts as its input sorts, and exactly one output sort,
> which defines its signature.

See [`NamedOperator`](@ref) and [`ArbitraryOperator`](@ref).
"""
abstract type AbstractOperator <: AbstractTerm end
# Expect each instance to have fields:
# - ordered sequence of zero or more input sorts #todo vector or tuple?
# - one output sort
# and support methods to:
# - compare operator signatures for equality using sort eqality
# - output sort type to test against place sort type (and others)
#
# Note that a zero input operator is a constant.

"return output sort of operator"
sortof(op::AbstractOperator) = error("sortof not defined for type $(typeof(op))")
"constants have arity of 0"
arity(op::AbstractOperator) = 0

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Note that Term is an abstract element in the pnml specification with no XML tag, we call that `AbstractTerm`.
Here we use `Term` as a concrete wrapper around **unparsed** high-level many-sorted algebra terms
**AND EXTEND** to also wrapping "single-sorted" values for other PNTDs.

By adding `Bool`, `Int`, `Float64` it is possible for `PnmlCoreNet` and `ContinuousNet`
to use `Term`s, and for implenting `default_bool_term`, `default_one_term`, `default_zero_term`.

See also [`iscontinuous`](@ref)

As part of the many-sorted algebra AST attached to nodes of a High-level Petri Net Graph,
`Term`s are contained within the <structure> element of an annotation label.
One XML child is expected below <structure> in the PNML schema.
The child's XML tag is used as the AST node type symbol.
Usually [`unparsed_tag`](@ref) is used to turn the child into a key, value pair.

#TODO is it safe to assume that Bool, Int, Float64 are in the carrier set/basis set?

# Functor

    (t::Term)([default_one_term(HLCoreNet())])

Term as functor requires a default value for missing values.

As a preliminary implementation evaluate a HL term by returning `:value` in `elements` or
evaluating `default_one_term(HLCoreNet())`.

See [`parse_marking_term`](@ref), [`parse_condition_term`](@ref), [`parse_inscription_term`](@ref),  [`parse_type`](@ref), [`parse_sorttype_term`](@ref), [`AnyElement`](@ref).

**Warning:** Much of the high-level is WORK-IN-PROGRESS.
The type parameter is a sort. We enumerate some of the built-in sorts allowed.
Is expected that the term will evaluate to that type.
Is that called a 'ground term'? 'basis set'?
External information may be used to select the output type.
"""
struct Term <: AbstractTerm
    tag::Symbol
    elements::Union{Bool, Int, Float64, XDVT} # concrete types #! too big for union splitting
    #! This should be replaced by Varible and AbstractOperator, handle union splitting there.
end
Term(s::AbstractString, e) = Term(Symbol(s), e) #~ Turn string into symbol.

tag(t::Term)::Symbol = t.tag
elements(t::Term) = t.elements
Base.eltype(t::Term) = typeof(elements(t))

value(t::Term) = _evaluate(t()) # Value of a Term is the functor's value. #! empty vector?

function Base.show(io::IO, t::Term)
    #@show typeof(elements(t))
    print(io, nameof(typeof(t)), "(")
    show(io, tag(t)); print(io, ", ");
    dict_show(io, elements(t), 0)
    print(io, ")")
end

(t::Term)() =  _term_eval(elements(t))

_term_eval(v::Any) = error("Term elements of type $(typeof(v)) not supported")
_term_eval(v::Number) = v
_term_eval(v::AbstractString) = parse(Bool, v)
_term_eval(v::DictType) = begin
    # Fake like we know how to evaluate a expression of the high-level terms
    # by embedding a `value` in "our hacks". Like the ones that add sorts to non-high-level nets.
    !isnothing(get(v, :value, nothing)) && return _term_eval(v[:value])
    #haskey(v, :value) && return _term_eval(v[:value]) LittleDict don't work

    CONFIG.warn_on_unimplemented &&
        @error("_term_eval needs to handle pnml ast in `v`! returning `false`");
    #Base.show_backtrace(stdout, backtrace()) # Save for obscure bugs.
    return false #
end

#(t::Term{Bool})(default = default_bool_term(HLCoreNet())) = begin end
#(t::Term{Int64})(default = default_one_term(HLCoreNet())) = begin end
#(t::Term{Float64})(default = default_one_term(HLCoreNet())) = begin end


#-----------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Variable refers to a varaible declaration.
Example input: <variable refvariable="varx"/>.

#TODO examples of use, modifying and accessing
"""
struct Variable <: AbstractTerm
    variableDecl::Symbol
end

# Only One
isvariable(tag::Symbol) = tag === :variable

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

boolean_operators = (:or,
                     :and,
                     :imply,
                     :not,
                     :equality,
                     :inequality,
                    )
isbooleanoperator(tag::Symbol) = tag in boolean_operators

isbuiltinoperator(tag::Symbol) = tag in builtin_operators

builtin_constants = (:numberconstant,
                     :dotconstant,
                     :booleanconstant,
                     )

boolean_constants = (:true,
                     :false)

isoperator(tag::Symbol) = isintegeroperator(tag) ||
                          ismultisetoperator(tag) ||
                          isbooleanoperator(tag) ||
                          tag in builtin_constants ||
                          tag === :tuple || tag === :useroperator
``
# struct Operator
#     tag::Symbol
#     out::Sort
#     in::Vector(Sort)
# end

struct PnmlTuple <: AbstractOperator end

"Create a multiset: multi`x"
struct numberof{T} <: AbstractOperator
    ms::Multiset{T} #TODO allow real multiplicity
end
numberof(x) = numberof(Multiset{sortof(x)}(x))

"""
$(TYPEDEF)
$(TYPEDFIELDS)

User defined operators only define an abbreviation. See [`NamedOperator`](@ref)
"""
struct UserOperator <: AbstractOperator
    declaration::Symbol # of a NamedOperator
end
UserOperator(str::AbstractString) = UserOperator(Symbol(str))

"""
$(TYPEDEF)
$(TYPEDFIELDS)

> ...arbitrary sorts and operators do not come with a definition of the sort or operation; they just introduce a new symbol without giving a definition for it.
"""
struct ArbitraryOperator{I<:AbstractSort} <: AbstractOperator
    declaration::Symbol
    input::Vector{AbstractSort} # Sorts
    output::I # sort of operator
end

#-----------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------
#
# PNML many-sorted algebra syntax tree term zoo follows.
#
#-----------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------

#TODO Should be booleanconstant/numberconstant: one_term, zero_term, bool_term?
# Term is really Variable and Opeator
term_value_type(::Type{<:PnmlType}) = eltype(IntegerSort) #Int
term_value_type(::Type{<:AbstractContinuousNet}) = eltype(RealSort)  #Float64

"""
$(TYPEDSIGNATURES)

One as integer, float, or empty term with a value of one.
"""
function default_one_term end
default_one_term(pntd::PnmlType) = Term(:one, one(term_value_type(pntd)))
default_one_term(x::Any) = throw(ArgumentError("expected a PnmlType, got: $(typeof(x))"))

"""
$(TYPEDSIGNATURES)

Zero as integer, float, or empty term with a value of zero.
"""
function default_zero_term end
default_zero_term(pntd::PnmlType) = Term(:zero, zero(term_value_type(pntd)))
default_zero_term(x::Any) = throw(ArgumentError("expected a PnmlType, got: $(typeof(x))"))

"""
$(TYPEDSIGNATURES)

True as boolean or term with a value of `true`.
"""
function default_bool_term end
default_bool_term(pntd::PnmlType) = Term(:bool, true)
default_bool_term(x::Any) = throw(ArgumentError("expected a PnmlType, got: $(typeof(x))"))
