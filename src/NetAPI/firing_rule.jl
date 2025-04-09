# Firing Rule

"""
    fire(incidence, enabled, marking) -> LVector

Return the marking vector after firing transition:   marking + incidence * enabled

`marking` LVector values added to product of `incidence'` matrix and firing vector `enabled`.
"""
function fire(incidence, enabled, m₀) #TODO move "lvector tools" section
    #println("fire")
    #@show typeof(incidence) enabled typeof(m₀)
    #@show permutedims(incidence) * enabled
    #! Multisets do not have negative multiplicities so fail here with incorrect marking!
    LVector(namedtuple(symbols(m₀), muladd(permutedims(incidence), enabled, m₀))) # old names, new values
end

function fire2(C, net, mx)
    if pntd(net) isa AbstractHLCore
        pntd(net) isa PT_HLPNG || println("firing $(pntd(net)) not implemented here, good luck")
    end
    fire(C, PNML.enabled(net, mx), mx)
end
