#=
evaluating a Variable does a lookup to return value of an instance of a sort.
? can variable be multiset (multiplicity > 1)?

evaluating an Operator also returns value of an instance of a sort.
Both scalar and multiset are possible.
=#

# Note that Term is an abstract element in the pnml specification with no XML tag, we call that `AbstractTerm`.

# As part of the many-sorted algebra AST attached to nodes of a High-level Petri Net Graph,
# `Term`s are contained within the <structure> element of an annotation label or operator def.
# One XML child is expected below <structure> in the PNML schema.
# The child's XML tag is used as the AST node type symbol.

# See [`parse_marking_term`](@ref), [`parse_condition_term`](@ref), [`parse_inscription_term`](@ref),
#  [`parse_type`](@ref), [`parse_sorttype_term`](@ref), [`AnyElement`](@ref).

#-------------------------------------------------------------------------
# Term is really Variable and Opeator
# term_value_type(::Type{<:PnmlType}) = eltype(IntegerSort) #Int
# term_value_type(::Type{<:AbstractContinuousNet}) = eltype(RealSort)  #Float64
# term_value_type(::Type{<:AbstractHLCore}) = eltype(DotSort)  #! basis of multiset

# Must be suitable as a marking, ie. a ground term without variables.

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
