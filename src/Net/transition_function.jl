"""
$(TYPEDSIGNATURES)

Transition function of a Petri Net.
Each transition has an input vector and an output vector.
Each labelled vector is indexed by the place on the other end of the arc.
Values are inscriptions of the arc.
"""
function transition_function end

transition_function(petrinet::AbstractPetriNet)     = transition_function(petrinet.net)
transition_function(net::PnmlNet)           = transition_function(net.pages[begin])
transition_function(net::PnmlNet, page_idx) = transition_function(net.pages[page_idx])
transition_function(page::Page)             = transition_function(page, transition_ids(page))
transition_function(page::Page, idvec::Vector{Symbol}) =
    LVector((;[t=>in_out(page, t) for t in idvec]...))

"""
$(TYPEDSIGNATURES)

Return tuple of input, output labelled vectors with key of place ids and
value of arc inscription's value for use as a transition function.
#TODO When do these get called "pre" and "post"?
"""
function in_out end

in_out(petrinet::AbstractPetriNet, transition_id::Symbol) = in_out(petrinet.net, transition_id)
in_out(net::PnmlNet, transition_id::Symbol)           = in_out(net.pages[begin], transition_id)
in_out(net::PnmlNet, transition_id::Symbol, page_idx) = in_out(net.pages[page_idx], transition_id)
in_out(page::Page, transition_id::Symbol) =
    (ins(page, transition_id), outs(page, transition_id))

"""
$(TYPEDSIGNATURES)
Return labeled vector of arcs of `p` that have `transition_id` as the target.
"""
function ins(p, transition_id::Symbol)
    LVector( (; [source(a)=>inscription(a) for a in tgt_arcs(p, transition_id)]...))
end

"""
$(TYPEDSIGNATURES)
Return labeled vector of arcs of `p` that have `transition_id` as the source.
"""
function outs(p, transition_id::Symbol)
    #isempty(src_arcs(p, transition_id)) && @warn "no src_arcs for $transition_id"
    LVector( (; [target(a)=>inscription(a) for a in src_arcs(p, transition_id)]...))
end
