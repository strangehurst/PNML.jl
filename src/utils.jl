"Return first true `f` of `v` or `nothing`."
function getfirst(f::Function, v)
    i = findfirst(f,v) # Cannot use nothing as an index.
    isnothing(i) ? nothing : v[i]
end


"""
Use PNML type as trait to select type of marking.
"""
markingtype(::PnmlType) = PTMarking
markingtype(::AbstractHLCore) = HLMarking

"""
Use PNML type as trait to select type of inscription.
"""
inscriptiontype(::PnmlType) = PTInscription
inscriptiontype(::AbstractHLCore) = HLInscription


"""
Use PNML type as trait to select valuetype of marking.
"""
markingvaluetype(::PnmlType) = Int
markingvaluetype(::AbstractContinuousNet) = Float64
markingvaluetype(::AbstractHLCore) = Term

"""
Use PNML type as trait to select type of inscription.
"""
inscriptionvaluetype(::PnmlType) = Int
inscriptionvaluetype(::AbstractContinuousNet) = Float64
inscriptionvaluetype(::AbstractHLCore) = Term
