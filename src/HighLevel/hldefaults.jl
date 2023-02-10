#------------------------------------------------------------------------------
default_condition(pntd::AbstractHLCore) = Condition(pntd, default_bool_term(pntd))
default_inscription(pntd::AbstractHLCore) = HLInscription("default", default_one_term(pntd))
default_marking(pntd::AbstractHLCore) = HLMarking(default_zero_term(pntd))

default_sort(::AbstractHLCore) = Sort() #! sort IS A TYPE of a multi-sorted algebra, not value!
