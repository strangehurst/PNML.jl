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
"reachability_graph"
function reachability_graph(net)
    @error "rechability graph" net
end
