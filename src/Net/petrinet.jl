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

#------------------------------------------------------------------------------------------
# Methods that should be implemented by concrete subtypes of AbstractPetriNet will throw an error.
#------------------------------------------------------------------------------------------

pid(::AbstractPetriNet)   = error("must implement id accessor")

places(::AbstractPetriNet)         = error("not implemented")
transitions(::AbstractPetriNet)    = error("not implemented")
arcs(::AbstractPetriNet)           = error("not implemented")
refplaces(::AbstractPetriNet)      = error("not implemented")
reftransitions(::AbstractPetriNet) = error("not implemented")

#------------------------------------------------------------------
place_ids(petrinet::AbstractPetriNet)             = place_ids(petrinet.net)
has_place(petrinet::AbstractPetriNet, id::Symbol) = has_place(petrinet.net, id)
place(petrinet::AbstractPetriNet, id::Symbol)     = place(petrinet.net, id)

marking(petrinet::AbstractPetriNet, placeid::Symbol) = marking(petrinet.net, placeid)
currentMarkings(petrinet::AbstractPetriNet) = currentMarkings(petrinet.net)

#------------------------------------------------------------------
transition_ids(petrinet::AbstractPetriNet)             = transition_ids(petrinet.net)
has_transition(petrinet::AbstractPetriNet, id::Symbol) = has_transition(petrinet.net, id)
transition(petrinet::AbstractPetriNet, id::Symbol)     = transition(petrinet.net, id)

condition(petrinet::AbstractPetriNet, trans_id::Symbol) = condition(petrinet.net, trans_id)
conditions(petrinet::AbstractPetriNet)                  = conditions(petrinet.net)

#------------------------------------------------------------------
arc_ids(petrinet::AbstractPetriNet)              = arc_ids(petrinet.net)
has_arc(petrinet::AbstractPetriNet, id::Symbol)  = has_arc(petrinet.net, id)
arc(petrinet::AbstractPetriNet, id::Symbol)      = arc(petrinet.net, id)

all_arcs(petrinet::AbstractPetriNet, id::Symbol) = all_arcs(petrinet.net, id)
src_arcs(petrinet::AbstractPetriNet, id::Symbol) = src_arcs(petrinet.net, id)
tgt_arcs(petrinet::AbstractPetriNet, id::Symbol) = tgt_arcs(petrinet.net, id)

inscription(petrinet::AbstractPetriNet, arc_id::Symbol) = inscription(petrinet.net, arc_id)
#! TODO inscriptions (plural)? For completeness?

#------------------------------------------------------------------
refplace_ids(petrinet::AbstractPetriNet)              = refplace_ids(petrinet.net)
has_refP(petrinet::AbstractPetriNet, ref_id::Symbol)  = has_refP(petrinet.net, ref_id)
refplace(petrinet::AbstractPetriNet, id::Symbol)      = refplace(petrinet.net, id)

reftransition_ids(petrinet::AbstractPetriNet)         = reftransition_ids(petrinet.net)
has_refT(petrinet::AbstractPetriNet, ref_id::Symbol)  = has_refP(petrinet.net, ref_id)
reftransition(petrinet::AbstractPetriNet, id::Symbol) = reftransition(petrinet.net, id)

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
