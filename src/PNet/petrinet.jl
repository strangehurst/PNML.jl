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

pnmlnet(petrinet::AbstractPetriNet) = petrinet.net

#------------------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------------------

pid(petrinet::AbstractPetriNet)   = pid(pnmlnet(petrinet))
name(petrinet::AbstractPetriNet)  = name(pnmlnet(petrinet))

places(petrinet::AbstractPetriNet)         = places(pnmlnet(petrinet))
transitions(petrinet::AbstractPetriNet)    = transitions(pnmlnet(petrinet))
arcs(petrinet::AbstractPetriNet)           = arcs(pnmlnet(petrinet))
refplaces(petrinet::AbstractPetriNet)      = refPlaces(pnmlnet(petrinet))
reftransitions(petrinet::AbstractPetriNet) = refTransitions(pnmlnet(petrinet))

#------------------------------------------------------------------
place_idset(petrinet::AbstractPetriNet)           = place_idset(pnmlnet(petrinet))
has_place(petrinet::AbstractPetriNet, id::Symbol) = has_place(pnmlnet(petrinet), id)
place(petrinet::AbstractPetriNet, id::Symbol)     = place(pnmlnet(petrinet), id)

marking(petrinet::AbstractPetriNet, id::Symbol) = marking(pnmlnet(petrinet), id)

"""
    currentMarkings(petrinet) -> LVector{marking_value_type(pntd)}

LVector labelled with place id and holding marking's value.
"""
currentMarkings(pn::AbstractPetriNet) = begin
    m1 = LVector((;[id => marking(p)() for (id,p) in pairs(placedict(pnmlnet(pn)))]...)) #! does this allocate?
    return m1
end

#------------------------------------------------------------------
transition_idset(petrinet::AbstractPetriNet)           = transition_idset(pnmlnet(petrinet))
has_transition(petrinet::AbstractPetriNet, id::Symbol) = has_transition(pnmlnet(petrinet), id)
transition(petrinet::AbstractPetriNet, id::Symbol)     = transition(pnmlnet(petrinet), id)

condition(petrinet::AbstractPetriNet, id::Symbol)      = condition(pnmlnet(petrinet), id)

"""
    conditions(petrinet) -> LVector{condition_value_type(pntd)}

LVector labelled with transition (#! not id) and holding condition (#! not value).
"""
conditions(pn::AbstractPetriNet) = begin
    net = pnmlnet(pn)
    LVector{condition_value_type(net)}(
        (; [trans_id => condition(t) for (trans_id,t) in pairs(transitiondict(net))]...))
end

#------------------------------------------------------------------
arc_idset(petrinet::AbstractPetriNet)            = arc_idset(pnmlnet(petrinet))
has_arc(petrinet::AbstractPetriNet, id::Symbol)  = has_arc(pnmlnet(petrinet), id)
arc(petrinet::AbstractPetriNet, id::Symbol)      = arc(pnmlnet(petrinet), id)

all_arcs(petrinet::AbstractPetriNet, id::Symbol) = all_arcs(pnmlnet(petrinet), id)
src_arcs(petrinet::AbstractPetriNet, id::Symbol) = src_arcs(pnmlnet(petrinet), id)
tgt_arcs(petrinet::AbstractPetriNet, id::Symbol) = tgt_arcs(pnmlnet(petrinet), id)

inscription(petrinet::AbstractPetriNet, arc_id::Symbol) = inscription(pnmlnet(petrinet), arc_id)

inscriptions(petrinet::AbstractPetriNet) = begin
    net = pnmlnet(petrinet)
    LVector{inscription_value_type(net)}(
        (;[arc_id => inscription(a)() for (arc_id,a) in pairs(arcdict(net))]...))
end

#------------------------------------------------------------------
refplace_idset(petrinet::AbstractPetriNet)            = refplace_idset(pnmlnet(petrinet))
has_refplace(petrinet::AbstractPetriNet, id::Symbol)  = has_refplace(pnmlnet(petrinet), id)
refplace(petrinet::AbstractPetriNet, id::Symbol)      = refplace(pnmlnet(petrinet), id)

reftransition_idset(petrinet::AbstractPetriNet)       = reftransition_idset(pnmlnet(petrinet))
has_reftransition(petrinet::AbstractPetriNet, id::Symbol) = has_reftransition(pnmlnet(petrinet), id)
reftransition(petrinet::AbstractPetriNet, id::Symbol) = reftransition(pnmlnet(petrinet), id)

"""
$(TYPEDSIGNATURES)

Return a transition-id labelled vector of rate values for transitions of a petri net.
"""
function rates end

function rates(petrinet::AbstractPetriNet)
    #LVector( (; [tid => (rate ∘ transition)(pn, tid) for tid in transition_idset(pn)]...))
    net = pnmlnet(petrinet)
    LVector(
        (;[tid => rate(t) for (tid, t) in pairs(transitiondict(net))]...))
end




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
