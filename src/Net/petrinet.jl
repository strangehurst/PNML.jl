using Base: Fix2, Fix1
"""
$(TYPEDEF)

Top-level of a **single network** in a pnml model that is some flavor of Petri Net.
Note that pnml can represent nets that are **not** Petri Nets.

Here is where specialization and restriction are applied to achive Proper Petri Behavior.

See [`PnmlModel`](@ref), [`PnmlType`](@ref).

# Extended

Additional constrants can be imposed. We want to run under the motto:
"syntax is not semantics, quack".

Since a PNML.Document model can contain multiple networks it is possible that
a higher-level will create multiple AbstractPetriNet instances, each a different type.

Multiple [`Page`](@ref)s can (are permitted to) be merged into one page
by [`flatten_pages!`](@ref) without losing any Petri Net semantics.
"""
abstract type AbstractPetriNet{PNTD<:PnmlType} end

function Base.getproperty(pn::AbstractPetriNet, prop_name::Symbol)
    if prop_name === :id
        return getfield(pn, :id)::Symbol
    elseif prop_name === :net
        return getfield(pn, :net)::PnmlNet
    end
    return getfield(pn, prop_name)
end

nettype(::AbstractPetriNet{T}) where {T <: PnmlType} = T

net(petrinet::AbstractPetriNet) = petrinet.net

#------------------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------------------

pid(petrinet::AbstractPetriNet)   = pid(net(petrinet))

places(petrinet::AbstractPetriNet)         = places(net(petrinet))
transitions(petrinet::AbstractPetriNet)    = transitions(net(petrinet))
arcs(petrinet::AbstractPetriNet)           = arcs(net(petrinet))
refplaces(petrinet::AbstractPetriNet)      = refPlaces(net(petrinet))
reftransitions(petrinet::AbstractPetriNet) = refTransitions(net(petrinet))

#------------------------------------------------------------------
place_idset(petrinet::AbstractPetriNet)           = place_idset(net(petrinet))
has_place(petrinet::AbstractPetriNet, id::Symbol) = has_place(net(petrinet), id)
place(petrinet::AbstractPetriNet, id::Symbol)     = place(net(petrinet), id)

marking(petrinet::AbstractPetriNet, placeid::Symbol) = marking(net(petrinet), placeid)
currentMarkings(petrinet::AbstractPetriNet) = currentMarkings(net(petrinet))

#------------------------------------------------------------------
transition_idset(petrinet::AbstractPetriNet)           = transition_idset(net(petrinet))
has_transition(petrinet::AbstractPetriNet, id::Symbol) = has_transition(net(petrinet), id)
transition(petrinet::AbstractPetriNet, id::Symbol)     = transition(net(petrinet), id)

condition(petrinet::AbstractPetriNet, trans_id::Symbol) = condition(net(petrinet), trans_id)
conditions(petrinet::AbstractPetriNet)                  = conditions(net(petrinet))

#------------------------------------------------------------------
arc_idset(petrinet::AbstractPetriNet)            = arc_idset(net(petrinet))
has_arc(petrinet::AbstractPetriNet, id::Symbol)  = has_arc(net(petrinet), id)
arc(petrinet::AbstractPetriNet, id::Symbol)      = arc(net(petrinet), id)

all_arcs(petrinet::AbstractPetriNet, id::Symbol) = all_arcs(net(petrinet), id)
src_arcs(petrinet::AbstractPetriNet, id::Symbol) = src_arcs(net(petrinet), id)
tgt_arcs(petrinet::AbstractPetriNet, id::Symbol) = tgt_arcs(net(petrinet), id)

inscription(petrinet::AbstractPetriNet, arc_id::Symbol) = inscription(net(petrinet), arc_id)
#TODO inscriptions (plural)? For completeness?

#------------------------------------------------------------------
refplace_idset(petrinet::AbstractPetriNet)            = refplace_idset(net(petrinet))
has_refP(petrinet::AbstractPetriNet, ref_id::Symbol)  = has_refP(net(petrinet), ref_id)
refplace(petrinet::AbstractPetriNet, id::Symbol)      = refplace(net(petrinet), id)

reftransition_idset(petrinet::AbstractPetriNet)       = reftransition_idset(net(petrinet))
has_refT(petrinet::AbstractPetriNet, ref_id::Symbol)  = has_refP(net(petrinet), ref_id)
reftransition(petrinet::AbstractPetriNet, id::Symbol) = reftransition(net(petrinet), id)

#-----------------------------------------------------------------
Base.summary(io::IO, pn::AbstractPetriNet) = print(io, summary(pn))
function Base.summary(pn::AbstractPetriNet)
    string(typeof(pn), " id ", pid(pn), ", ",
        length(places(pn)), " places, ",
        length(transitions(pn)), " transitions, ",
        length(arcs(pn)), " arcs")
end

function Base.show(io::IO, pn::AbstractPetriNet)
    println(io, summary(pn))
    println(io, "places")
    println(io, places(pn))
    println(io, "transitions")
    println(io, transitions(pn))
    println(io, "arcs")
    print(io, arcs(pn))
end
