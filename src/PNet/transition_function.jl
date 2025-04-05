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
    LVector((;[tid => in_out(net, tid) for tid in PNML.transition_idset(net)]...))

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

Inscription values labeled with source place id for arcs with `transition_id` as the target id.
"""
ins(net::PnmlNet, transition_id::Symbol) = LVector((; collect(in_inscriptions(net, transition_id))...))

"""
    outs(net, transition_id) -> LVector

Inscription values labeled with target place id for arcs with `transition_id` as the source id.
"""
outs(net::PnmlNet, transition_id::Symbol) =
        LVector((; collect(out_inscriptions(net, transition_id))...))

#
# See input flow #todo cite ISO 15909-1:2019 (part 1, 2ed)
"""
    in_inscriptions(net, transitionid) -> Iterator

Iterate over preset of transition, returning source place id => inscription value pairs.
"""
function in_inscriptions(net::PnmlNet, transitionid)
    Iterators.map(PNML.preset(net, transitionid)) do placeid
        a = PNML.arc(net, placeid, transitionid)
        PNML.source(a) => PNML.inscription(a)(NamedTuple())
    end
end

# See output flow #todo cite  ISO 15909-1:2019 (part 1, 2ed)
"""
    out_inscriptions(net, transitionid) -> Iterator

Iterate over postset of transition, returning target place id => inscription value pairs.
"""
function out_inscriptions(net::PnmlNet, transitionid)
    Iterators.map(PNML.postset(net, transitionid)) do placeid
        a = PNML.arc(net, transitionid, placeid)
        PNML.target(a) => PNML.inscription(a)(NamedTuple())
    end
end
