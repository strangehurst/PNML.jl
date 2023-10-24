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
"""
abstract type AbstractOperator end

"""
$(TYPEDEF)
$(TYPEDFIELDS)

Note that Term is an abstract element in the pnml specification with no XML tag.
Here we use it as a concrete wrapper around high-level many-sorted algebra terms
**AND EXTEND** to also wrapping "single-sorted" values.

By adding `Bool`, `Int`, `Float64` it is possible for `PnmlCoreNet` and `ContinuousNet`
to use `Term`s, and for implenting `default_bool_term`, `default_one_term`, `default_zero_term`.

See also [`iscontinuous`](@ref)

As part of the many-sorted algebra attached to nodes of a High-level Petri Net Graph,
Term`s are contained within the <structure> element of an annotation label,
See [`HLAnnotation`](@ref) concrete subtypes.

#TODO is it safe to assume that Bool, Int, Float64 are in the carrier set/basis set?

#! HL term is currently implemented as a wrapper of Vector{AnyXmlNode}. A tree of symbols with leafs that are strings.

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
When the elements' value is a Vector{AnyXmlNode} external information is used to select the output type.
"""
struct Term #= {T<:Union{Bool, Int, Float64}} =# <: AbstractTerm
    tag::Symbol
    elements::Union{Bool, Int, Float64, Vector{AnyXmlNode}}
end
Term(p::Pair{Symbol, Vector{AnyXmlNode}}) = Term(p.first, p.second)

tag(t::Term)::Symbol = t.tag
elements(t::Term) = t.elements
Base.eltype(t::Term) = typeof(elements(t))
#Base.eltype(t::Term{T}) where {T} = T

#!has_value(t::Term) = Iterators.any(x -> !isa(x, Number) && tag(x) === :value, t.elements)
value(t::Term) = _evaluate(t()) # Value of a Term is the functor's value. #! empty vector?

(t::Term)() = begin
    if typeof(elements(t)) <: Number
        return elements(t)
    else # is Vector{AnyXmlNode}
        # Fake like we know how to evaluate a expression of the high-level terms.
        # Find any `:value` tag in elements and assume is a boolean string.
        i = findfirst(x -> !isa(x, Number) && (tag(x) === :value), t.elements)
        if !isnothing(i)
            return value(t.elements[i]) == "true" # should be a booleanconstant
        else
            println("(t::Term) needs to handle term ast! returning nothing");
            map(println, elements(t))
            #todo Until then, return a random value in the   domain.
            #
            #! v = _evaluate(default)
            return nothing
        end
    end
end
#(t::Term{Bool})(default = default_bool_term(HLCoreNet())) = begin end
#(t::Term{Int64})(default = default_one_term(HLCoreNet())) = begin end
#(t::Term{Float64})(default = default_one_term(HLCoreNet())) = begin end


#-----------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Example input: <variable refvariable="varx"/>
"""
struct Variable <: AbstractTerm
    variableDecl::Symbol
end

#TODO Define something for these. They are not really traits.
struct BuiltInOperator <: AbstractOperator end
struct BuiltInConst <: AbstractOperator end
struct MultiSetOperator <: AbstractOperator end
struct PnmlTuple <: AbstractOperator end

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
"""
struct ArbitraryOperator{I<:AbstractSort} <: AbstractOperator
    "Identity of operators's declaration."
    declaration::Symbol
    input::I
    output::Vector{AbstractSort} # Sorts
end

#-----------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------
#
# PNML many-sorted algebra syntax tree term zoo follows.
#
#-----------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------

#TODO Should be booleanconstant/numberconstant: one_term, zero_term, bool_term?

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
