"Return first true `f` of `v` or `nothing`."
function getfirst(f::Function, v)
    i = findfirst(f, v) # Cannot use nothing as an index.
    isnothing(i) ? nothing : v[i]
end

#! TODO Move this somewhere.
"""
Use PNML type as trait to select type of marking.
"""
function markingtype end

"""
Use PNML type as trait to select valuetype of marking.
"""
function markingvaluetype end

"""
Use PNML type as trait to select type of inscription.
"""
function inscriptiontype end

"""
Use PNML type as trait to select type of inscription.
"""
function inscriptionvaluetype end

markingtype(::PnmlType) = Marking
markingvaluetype(::PnmlType) = Int
markingvaluetype(::AbstractContinuousNet) = Float64

inscriptiontype(::PnmlType) = Inscription
inscriptionvaluetype(::PnmlType) = Int
inscriptionvaluetype(::AbstractContinuousNet) = Float64

markingtype(::AbstractHLCore) = HLMarking
markingvaluetype(::AbstractHLCore) = Term

inscriptiontype(::AbstractHLCore) = HLInscription
inscriptionvaluetype(::AbstractHLCore) = Term
