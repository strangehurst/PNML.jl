#------------------------------------------------------------------------------
default_condition(pntd::AbstractHLCore) = Condition(default_bool_term(pntd))
default_inscription(pntd::AbstractHLCore) = HLInscription("default", default_one_term(pntd))
default_marking(pntd::AbstractHLCore) = HLMarking(default_zero_term(pntd))

default_sort(pntd::AbstractHLCore) = SortType("default", default_one_term(pntd)) #! sort IS A TYPE, not value!
