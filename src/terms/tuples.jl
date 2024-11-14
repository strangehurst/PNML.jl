#
"""
The <tuple> operator is used to wrap an ordered sequence of AbstractTerm instances.
When evaluated each of the expressions will be a ground term of a placesort that will be a ProductSort.
"""
struct PnmlTuple
    terms::Vector{AbstractTerm}
end

terms(t::PnmlTuple) = t.terms
(t::PnmlTuple)() = error("(t::PnmlTuple)() not implemented, t = repr(t)") #Iterators.map(_evaluate, terms(t))

#todo This should implement the operator interface? TermInterface?
#todo contents are PnmlExpressions (what constraints, PNTD?)
#todo subject to term relacement by MetaTheory.jl, SymbolicUtils.jl, et al.
#todo something evaluates the PnmlExpressions, when/why
#todo what is done with the tuple contents?
