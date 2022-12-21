"""
$(TYPEDSIGNATURES)
Inscriptions, Markings, Conditions evaluate a value that may be simple or a functor.
"""
function _evaluate end
_evaluate(x::Any) = x # identity
_evaluate(x::AbstractTerm) = x() # functor
_evaluate(x::AbstractSort) = x() # functor
_evaluate(x::AbstractLabel) = x() # functor
