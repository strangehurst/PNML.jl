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
