# Firing rules
#=
find a transition with all input place marking >= arc inscription
    and not suppressed due to condition, inhibit arcs, output capacity, et al

    foreach input
        map tokens to variables
        remove tokens from inputs
    foreach output
        map variables to tokens
        add tokens to outputs
=#

input_matrix(petrinet::AbstractPetriNet, marking) = input_matrix(pnmlnet(petrinet), marking)
output_matrix(petrinet::AbstractPetriNet, marking) = output_matrix(pnmlnet(petrinet), marking)
incidence_matrix(petrinet::AbstractPetriNet, marking) = incidence_matrix(pnmlnet(petrinet), marking)

enabled(petrinet::AbstractPetriNet, marking) = enabled(pnmlnet(petrinet), marking)


#^+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

"""
    fire(incidence, enabled, marking) -> LVector

Return the marking after firing transition:   marking + incidence * enabled

`marking` LVector values added to product of `incidence'` matrix and firing vector `enabled`.
"""
function fire(incidence, enabled, m₀) #TODO move "lvector tools" section
    #println("fire")
    #@show typeof(incidence) enabled typeof(m₀)
    #@show permutedims(incidence) * enabled
    #! Multisets do not have negative multiplicities so HL Nets fail here!
    m₁ = muladd(permutedims(incidence), enabled, m₀) # need cardinality for PT_HLPNG marking vector
    LVector(namedtuple(symbols(m₀), m₁)) # old names, new values
end

function fire2(C, anet, mx)
    pntd = nettype(anet)
    if pntd <: PT_HLPNG
        fire(C, PNML.enabled(anet.net, mx), mx)
    elseif pntd <: AbstractHLCore
        println("fire $(repr(pntd)) not implemented here, good luck")
        fire(C, PNML.enabled(anet.net, mx), mx)
    else
        fire(C, PNML.enabled(anet.net, mx), mx)
    end
end

"reachability_graph"
function reachability_graph(net)
    @error "rechability graph" net
end
