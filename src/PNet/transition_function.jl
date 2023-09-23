"""
transition_function(petrinet::AbstractPetriNet) -> LVector{Symbol, Tuple{LVector,LVector}

Transition function of a Petri Net.
Each transition has an input vector and an output vector.
Each labelled vector is indexed by the place on the other end of the arc.
Values are inscriptions of the arc.

# keys are transition ids
# values are tuple of input, output labeled vectors,
# label is source or target place id - inscription (integer?)

```julia
tfun = LVector(
    birth=(LVector(rabbits=1.0), LVector(rabbits=2.0)),
    predation=(LVector(wolves=1.0, rabbits=1.0), LVector(wolves=2.0)),
    death=(LVector(wolves=1.0), LVector()),
)

Vector{Tuple{Dict{Symbol, Number},Dict{Symbol, Number}}

Δ = 3-element LabelledArrays.LArray{Tuple{LabelledArrays.LArray{Float64, 1, Vector{Float64}},
                                          LabelledArrays.LArray{T, 1, D} where {T, D<:AbstractVector{T}}},
                                    1,
                 Vector{Tuple{LabelledArrays.LArray{Float64, 1, Vector{Float64}},
                              LabelledArrays.LArray{T, 1, D}  where {T, D<:AbstractVector{T}}}},
(:birth, :predation, :death)}:

[tid => ([src=>inscription], [tgt=>inscription])]
```
"""
function transition_function end

transition_function(petrinet::AbstractPetriNet) = transition_function(pnmlnet(petrinet))
transition_function(net::PnmlNet) =
    LVector((;[tid => in_out(net, tid) for tid in transition_idset(net)]...))

"""
$(TYPEDSIGNATURES)

Return tuple of input, output labelled vectors with key of place ids and
value of arc inscription's value for use as a transition function.
#TODO When do these get called "pre" and "post"?
"""
function in_out end
# Look in the PnmlNet
in_out(petrinet::AbstractPetriNet, transition_id::Symbol) = in_out(pnmlnet(petrinet), transition_id)
in_out(net::PnmlNet, transition_id::Symbol) = (ins(net, transition_id), outs(net, transition_id))

"""
    ins(net, transition_id) -> LVector

    Return vector of inscription values labeled with source place id for arcs with `transition_id` as the target id.
"""
ins(net, transition_id::Symbol) = LVector((; collect(in_inscriptions(net, transition_id))...))

"""
    outs(net, transition_id) -> LVector

Return vector of inscription values labeled with target place id for arcs with `transition_id` as the source id.
"""
outs(net, transition_id::Symbol) = LVector((; collect(out_inscriptions(net, transition_id))...))

# Given x ∈ S ∪ T , the set •x = {y | (y, x) ∈ F } is the preset of x.
"Iterate input place ids of transition."
preset(net, transition_id) = Iterators.map(arc->source(arc), tgt_arcs(net, transition_id))

# Given x ∈ S ∪ T , the set x• = {y | (x, y) ∈ F } is the postset of x.
"Iterate output place ids of transition."
postset(net, transition_id) = Iterators.map(arc->target(arc), src_arcs(net, transition_id))

in_inscriptions(net, transitionid) = Iterators.map(preset(net, transitionid)) do placeid
    a = arc(net, placeid, transitionid)
    #@show placeid transitionid a source(a) inscription(a)
    source(a) => inscription(a)
end

out_inscriptions(net, transitionid) = Iterators.map(postset(net, transitionid)) do placeid
    a = arc(net, transitionid, placeid)
    #@show transitionid placeid a target(a) inscription(a)
    target(a) => inscription(a)
end
