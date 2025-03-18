#
"""
The `<tuple>` operator is used to wrap an ordered collection of `AbstractTerm` instances.
When evaluated each term will have the same sort as corresponding element of a ProductSort.

`PnmlTupleEx` is the `PnmlExpr` that produces an expression calling `pnmltuple`.
"""
const PnmlTuple = Tuple

"""
    pnmltuple(args...) -> Tuple

TODO: Use NamedTuple, where names are a tuple of corresponding sort REFIDs
"""
pnmltuple(args...) = tuple(args...)
terms(t::PnmlTuple) = identity(t)
