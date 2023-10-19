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

initial_marking(petrinet::AbstractPetriNet, id::Symbol) = initial_marking(pnmlnet(petrinet), id)

#------------------------------------------------------------------
transition_idset(petrinet::AbstractPetriNet)           = transition_idset(pnmlnet(petrinet))
has_transition(petrinet::AbstractPetriNet, id::Symbol) = has_transition(pnmlnet(petrinet), id)
transition(petrinet::AbstractPetriNet, id::Symbol)     = transition(pnmlnet(petrinet), id)

condition(petrinet::AbstractPetriNet, id::Symbol)      = condition(pnmlnet(petrinet), id)

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
    #!LVector{inscription_value_type(net)}(
    LVector((;[arc_id => inscription(a) for (arc_id,a) in pairs(arcdict(net))]...))
end

#------------------------------------------------------------------
refplace_idset(petrinet::AbstractPetriNet)            = refplace_idset(pnmlnet(petrinet))
has_refplace(petrinet::AbstractPetriNet, id::Symbol)  = has_refplace(pnmlnet(petrinet), id)
refplace(petrinet::AbstractPetriNet, id::Symbol)      = refplace(pnmlnet(petrinet), id)

reftransition_idset(petrinet::AbstractPetriNet)       = reftransition_idset(pnmlnet(petrinet))
has_reftransition(petrinet::AbstractPetriNet, id::Symbol) = has_reftransition(pnmlnet(petrinet), id)
reftransition(petrinet::AbstractPetriNet, id::Symbol) = reftransition(pnmlnet(petrinet), id)

"""
    rates(petrinet::AbstractPetriNet) -> LVector

Return a transition-id labelled vector of rate values.

We allow all PNML nets to be stochastic Petri nets. See [`rate`](@ref).
"""
function rates(petrinet::AbstractPetriNet)
    net = pnmlnet(petrinet)
    @assert rate_value_type(net) <: Real #! debug?
    LVector((;[tid => rate(t) for (tid, t) in pairs(transitiondict(net))]...))
end


#-----------------------------------------------------------------
#=
Given x ∈ S ∪ T
  - the set •x = {y | (y, x) ∈ F } is the preset of x.
  - the set x• = {y | (x, y) ∈ F } is the postset of x.
=#
"""
Iterate ids of input (arc source)) for output transition or place `id`.

See [`in_inscriptions`](@ref) and [`transition_function`](@ref).
"""
preset(net, id) = Iterators.map(arc->source(arc), tgt_arcs(net, id))

"""
Iterate ids of output (arc target)) for source transition or place `id`.

See [`out_inscriptions`](@ref) and [`transition_function`](@ref).
"""
postset(net, id) = Iterators.map(arc->target(arc), src_arcs(net, id))

"Input matrix"
function input_matrix(petrinet::AbstractPetriNet)
    net = pnmlnet(petrinet)
    I = Matrix{inscription_value_type(net)}(undef, length(transition_idset(net)), length(place_idset(net)))
    for (t,transition_id) in enumerate(ransition_idset(net))
        for (p,place_id) in enumerate(place_idset(net))
            a = arc(pn, place_id, transition_id)
            @inbounds I[t,p] = isnothing(a) ? zero(inscription_value_type(net)) : inscription(a)
        end
    end
    return I
end

"Output Matrix"
function output_matrix(petrinet::AbstractPetriNet)
    net = pnmlnet(petrinet)
    O = Matrix{inscription_value_type(net)}(undef, length(transition_idset(net)), length(place_idset(net)))
    for (t,transition_id) in enumerate(ransition_idset(net))
        for (p,place_id) in enumerate(place_idset(net))
            a = arc(net, transition_id, place_id)
            @inbounds O[t, p] = isnothing(a) ? zero(inscription_value_type(net)) : inscription(a)
        end
    end
    return O
end

"""
    incidence_matrix(petrinet) -> LArray

C[transition,place] = inscription(transition,place) - inscription(place,transition)
"""
function incidence_matrix(petrinet::AbstractPetriNet)
    net = pnmlnet(petrinet)
    #TODO  Make Labelled Matrix? ComponentArray?
    println("incidence_matrix ", length(transition_idset(net)), " x ", length(place_idset(net)))
    C = Matrix{inscription_value_type(net)}(undef, length(transition_idset(net)), length(place_idset(net)))
    z = zero(inscription_value_type(net))
    for (t,transition_id) in enumerate(transition_idset(net))
        for (p,place_id) in enumerate(place_idset(net))
            tp = arc(net, transition_id, place_id)
            pt = arc(net, place_id, transition_id)

            c = (isnothing(tp) ? z : inscription(tp)) - (isnothing(pt) ? z : inscription(pt))
            @inbounds C[t, p] = c
        end
    end
    return C
end

"""
    initial_markings(petrinet) -> LVector{marking_value_type(pntd)}

LVector labelled with place id and holding initial marking's value.
"""
initial_markings(petrinet::AbstractPetriNet) = begin
    net = pnmlnet(petrinet)
    m1 = LVector((;[id => initial_marking(p)() for (id,p) in pairs(placedict(net))]...))
    return m1
end

"""
    conditions(petrinet) -> LVector{condition_value_type(pntd)}

LVector labelled with transition id and holding its condition's value.
"""
conditions(petrinet::AbstractPetriNet) = begin
    net = pnmlnet(petrinet)
    #!LVector{condition_value_type(net)}(
    LVector((;[id => condition(t) for (id, t) in pairs(transitiondict(net))]...))
end

"""
    enabled(::AbstractPetriNet, ::LVector) -> LVector

Returns labelled vector of id=>boolean where `true` means transitionid is enabled at marking.
"""
function enabled(petrinet::AbstractPetriNet, marking)
    net = pnmlnet(petrinet)
    #!LVector{Bool}(
    LVector((;[t => all(p -> marking[p] >= inscription(arc(net,p,t)), preset(net, t)) for t in transition_idset(net)]...))
end

"""
Return the marking after firing transition.
M1 = M0 + Cf.
M0 is the initial marking vector, f is the firing vector, i.e. which transition is to fire
and C is the incidence matrix.
"""
function fire!(incidence, enabled, mₒ)
    m₁ = muladd(incidence', enabled, mₒ)
    LVector(symbols(m₀), m₁)
end

""
function reachability_graph(net)
end

#-----------------------------------------------------------------
# Show and Tell Section:
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