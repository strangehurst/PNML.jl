#
"""
The `<tuple>` operator is used to wrap an ordered sequence of AbstractTerm instances.
When evaluated each of the expressions will have the same sort as in the ProductSort.

PnmlTupleEx is the PnmlExpr that produces an expression calling pnmltuple.
"""
const PnmlTuple = Tuple
# ProductSort has ordered collection of sorts. corresponding to terms' sorts.
#? How do we locate the ProductSort? When? It will be the basis of a multiset.

# Use NamedTuple, where names are a tuple of sort REFIDs
pnmltuple(args...) = tuple(args...)
terms(t::PnmlTuple) = identity(t)

#todo This should implement the operator interface? TermInterface?
#todo contents are PnmlExpressions (what constraints, PNTD?)
#todo subject to term relacement by MetaTheory.jl, SymbolicUtils.jl, et al.
#todo something evaluates the PnmlExpressions, when/why
#todo what is done with the tuple contents?
