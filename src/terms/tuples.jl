#
"""
ISO 15909 Standard considers Tuple to be an Operator.

The `<tuple>` operator is used to wrap an ordered collection of `AbstractTerm` instances.
When evaluated each term will have the same sort as corresponding element of a ProductSort.

[`PnmlTupleEx`](@ref) is the `PnmlExpr` that produces an expression calling `pnmltuple`
to create a Julia `Tuple` after evaluating all arguments.
"""
const PnmlTuple = Tuple

"""
    pnmltuple(args...) -> Tuple

See [`PnmlTupleEx`](@ref)
"""
pnmltuple(args...) = tuple(args...)
terms(t::PnmlTuple) = identity(t)
