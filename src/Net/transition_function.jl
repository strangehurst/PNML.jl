"""
$(TYPEDSIGNATURES)

Transition function of a Petri Net.
Each transition has an input vector and an output vector.
Each labelled vector is indexed by the place on the other end of the arc.
Values are inscriptions of the arc.
"""
function transition_function end

transition_function(petrinet::AbstractPetriNet) = transition_function(petrinet.net)
transition_function(net::PnmlNet) = transition_function((first ∘ pages)(net)) #! Assumes flattened!
transition_function(page::Page)   = transition_function(page, transition_idset(page))
#TODO Use iterator
transition_function(page::Page, idset) = LVector((;[tid => in_out(page, tid) for tid in idset]...))

"""
$(TYPEDSIGNATURES)

Return tuple of input, output labelled vectors with key of place ids and
value of arc inscription's value for use as a transition function.
#TODO When do these get called "pre" and "post"?
"""
function in_out end
# Look in the PnmlNet
in_out(petrinet::AbstractPetriNet, transition_id::Symbol) = in_out(petrinet.net, transition_id)
in_out(net::PnmlNet, transition_id::Symbol) = in_out((first ∘ pages)(net), transition_id)
in_out(page::Page, transition_id::Symbol)   = (ins(page, transition_id), outs(page, transition_id))

"""
$(TYPEDSIGNATURES)
Return labeled vector of arcs of `p` that have `transition_id` as the target.
"""
function ins(p, transition_id::Symbol)
    LVector( (; [source(a) => inscription(a) for a in tgt_arcs(p, transition_id)]...))
end

"""
$(TYPEDSIGNATURES)
Return labeled vector of arcs of `p` that have `transition_id` as the source.
"""
function outs(p, transition_id::Symbol)
    #isempty(src_arcs(p, transition_id)) && @warn "no src_arcs for $transition_id"
    LVector( (; [target(a) => inscription(a) for a in src_arcs(p, transition_id)]...))
end
