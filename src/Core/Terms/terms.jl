#=
evaluating a Variable does a lookup to return value of an instance of a sort.
? can variable be multiset (multiplicity > 1)?

evaluating an Operator also returns value of an instance of a sort.
Both scalar and multiset are possible.

What is the value of a multiset? Tuple multiplicity, instance of sort.
Also note that symmetric nets donot allow places to be multiset.
=#

# Note that Term is an abstract element in the pnml specification with no XML tag, we call that `AbstractTerm`.

# As part of the many-sorted algebra AST attached to nodes of a High-level Petri Net Graph,
# `Term`s are contained within the <structure> element of an annotation label or operator def.
# One XML child is expected below <structure> in the PNML schema.
# The child's XML tag is used as the AST node type symbol.

# See [`parse_marking_term`](@ref), [`parse_condition_term`](@ref), [`parse_inscription_term`](@ref),  [`parse_type`](@ref), [`parse_sorttype_term`](@ref), [`AnyElement`](@ref).

# _term_eval(v::Any) = error("Term elements of type $(typeof(v)) not supported")
# _term_eval(v::Number) = v
# _term_eval(v::AbstractString) = parse(Bool, v)
# _term_eval(v::DictType) = begin
#     # Fake like we know how to evaluate a expression of the high-level terms
#     # by embedding a `value` in "our hacks". Like the ones that add sorts to non-high-level nets.
#     !isnothing(get(v, :value, nothing)) && return _term_eval(v[:value])
#     #haskey(v, :value) && return _term_eval(v[:value]) LittleDict don't work

#     CONFIG[].warn_on_unimplemented &&
#         @error("_term_eval needs to handle pnml ast in `v`! returning `false`");
#     #Base.show_backtrace(stdout, backtrace()) # Save for obscure bugs.
#     return false #
# end



#-----------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------
#
# PNML many-sorted algebra syntax tree term zoo follows.
#
#-----------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------

#-------------------------------------------------------------------------
# Term is really Variable and Opeator
# term_value_type(::Type{<:PnmlType}) = eltype(IntegerSort) #Int
# term_value_type(::Type{<:AbstractContinuousNet}) = eltype(RealSort)  #Float64
# term_value_type(::Type{<:AbstractHLCore}) = eltype(DotSort)  #! basis of multiset

# Must be suitable as a marking, ie. a ground term without variables.
