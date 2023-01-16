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
a higher-level will create multiple PetriNet instances, each a different type.

Multiple [`Page`](@ref) can (are permitted to) be merged into one page
by [`flatten_pages!`](@ref) without losing any Petri Net semantics.
"""
abstract type PetriNet{PNTD<:PnmlType} end

nettype(::PetriNet{T}) where {T <: PnmlType} = T

#------------------------------------------------------------------------------------------
# Methods that should be implemented by concrete subtypes of PetriNet will throw an error.
#------------------------------------------------------------------------------------------

pid(::PetriNet)   = error("must implement id accessor")
pages(::PetriNet) = error("not implemented")
places(::PetriNet)         = error("not implemented")
transitions(::PetriNet)    = error("not implemented")
arcs(::PetriNet)           = error("not implemented")
refplaces(::PetriNet)      = error("not implemented")
reftransitions(::PetriNet) = error("not implemented")

#------------------------------------------------------------------
place_ids(petrinet::PetriNet)             = place_ids(petrinet.net)
has_place(petrinet::PetriNet, id::Symbol) = has_place(petrinet.net, id)
place(petrinet::PetriNet, id::Symbol)     = place(petrinet.net, id)

marking(petrinet::PetriNet, placeid::Symbol) = marking(petrinet.net, placeid)
currentMarkings(petrinet::PetriNet) = currentMarkings(petrinet.net)

#------------------------------------------------------------------
transition_ids(petrinet::PetriNet)             = transition_ids(petrinet.net)
has_transition(petrinet::PetriNet, id::Symbol) = has_transition(petrinet.net, id)
transition(petrinet::PetriNet, id::Symbol)     = transition(petrinet.net, id)

condition(petrinet::PetriNet, trans_id::Symbol) = condition(petrinet.net, trans_id)
conditions(petrinet::PetriNet)                  = conditions(petrinet.net)

#------------------------------------------------------------------
arc_ids(petrinet::PetriNet)              = arc_ids(petrinet.net)
has_arc(petrinet::PetriNet, id::Symbol)  = has_arc(petrinet.net, id)
arc(petrinet::PetriNet, id::Symbol)      = arc(petrinet.net, id)

all_arcs(petrinet::PetriNet, id::Symbol) = all_arcs(petrinet.net, id)
src_arcs(petrinet::PetriNet, id::Symbol) = src_arcs(petrinet.net, id)
tgt_arcs(petrinet::PetriNet, id::Symbol) = tgt_arcs(petrinet.net, id)

inscription(petrinet::PetriNet, arc_id::Symbol)  = inscription(petrinet.net, arc_id)
#! TODO inscriptions? For completeness?
#------------------------------------------------------------------
refplace_ids(petrinet::PetriNet)              = refplace_ids(petrinet.net)
has_refP(petrinet::PetriNet, ref_id::Symbol)  = has_refP(petrinet.net, ref_id)
refplace(petrinet::PetriNet, id::Symbol)      = refplace(petrinet.net, id)

reftransition_ids(petrinet::PetriNet)         = reftransition_ids(petrinet.net)
has_refT(petrinet::PetriNet, ref_id::Symbol)  = has_refP(petrinet.net, ref_id)
reftransition(petrinet::PetriNet, id::Symbol) = reftransition(petrinet.net, id)

#-----------------------------------------------------------------
Base.summary(io::IO, pn::PetriNet) = print(io, summary(pn))
function Base.summary(pn::PetriNet)
    string(typeof(pn), " id ", pid(pn), ", ",
        length(places(pn)), " places, ",
        length(transitions(pn)), " transitions, ",
        length(arcs(pn)), " arcs")
end

function Base.show(io::IO, pn::PetriNet)
    println(io, summary(pn))
    println(io, "places")
    println(io, places(pn))
    println(io, "transitions")
    println(io, transitions(pn))
    println(io, "arcs")
    print(io, arcs(pn))
end
