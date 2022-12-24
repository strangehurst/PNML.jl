#

#------------------------------------------------------------------------------
default_condition(p::AbstractHLCore) = Condition(p, true) #! should be a term
default_inscription(pntd::AbstractHLCore) = default_one_term(pntd)
default_marking(pntd::AbstractHLCore) = HLMarking(default_zero_term(pntd))
