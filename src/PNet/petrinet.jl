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

# Interface is having id::Symbol, net::PnmlNet.
function Base.getproperty(pn::AbstractPetriNet, prop_name::Symbol)
    if prop_name === :id
        return getfield(pn, :id)::Symbol
    elseif prop_name === :net
        return getfield(pn, :net)::PnmlNet
    end
    return getfield(pn, prop_name)
end

nettype(::AbstractPetriNet{T}) where {T <: PnmlType} = T

#TODO Is redundant copy of id in petri net and pnml net needed/wanted?
pid(petrinet::AbstractPetriNet)     = petrinet.id # maybe petrinet.id === pid(pnmlnet(petrinet))
pnmlnet(petrinet::AbstractPetriNet) = petrinet.net

#------------------------------------------------------------------------------------------
# Forward MANY THINGS to the IR implementation pnmlnet.
# TODO Adopt a forwarder?
# TODO
#------------------------------------------------------------------------------------------
name(petrinet::AbstractPetriNet)           = name(pnmlnet(petrinet))
places(petrinet::AbstractPetriNet)         = places(pnmlnet(petrinet))
transitions(petrinet::AbstractPetriNet)    = transitions(pnmlnet(petrinet))
arcs(petrinet::AbstractPetriNet)           = arcs(pnmlnet(petrinet))
refplaces(petrinet::AbstractPetriNet)      = refPlaces(pnmlnet(petrinet))
reftransitions(petrinet::AbstractPetriNet) = refTransitions(pnmlnet(petrinet))

npages(pn::AbstractPetriNet)          = npages(pnmlnet(pn))
nplaces(pn::AbstractPetriNet)         = nplaces(pnmlnet(pn))
ntransitions(pn::AbstractPetriNet)    = ntransitions(pnmlnet(pn))
narcs(pn::AbstractPetriNet)           = narcs(pnmlnet(pn))
nrefplaces(pn::AbstractPetriNet)      = nrefplaces(pnmlnet(pn))
nreftransitions(pn::AbstractPetriNet) = nreftransitions(pnmlnet(pn))

#------------------------------------------------------------------
"Return pnmlnet's place_idset"
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

#------------------------------------------------------------------
refplace_idset(petrinet::AbstractPetriNet)            = refplace_idset(pnmlnet(petrinet))
has_refplace(petrinet::AbstractPetriNet, id::Symbol)  = has_refplace(pnmlnet(petrinet), id)
refplace(petrinet::AbstractPetriNet, id::Symbol)      = refplace(pnmlnet(petrinet), id)

reftransition_idset(petrinet::AbstractPetriNet)       = reftransition_idset(pnmlnet(petrinet))
has_reftransition(petrinet::AbstractPetriNet, id::Symbol) = has_reftransition(pnmlnet(petrinet), id)
reftransition(petrinet::AbstractPetriNet, id::Symbol) = reftransition(pnmlnet(petrinet), id)


#####################################################################################
# Labelled Vectors
#####################################################################################

"""
    inscriptions(petrinet::AbstractPetriNet) -> LVector[id(arc) => inscription(arc)]
"""
function inscriptions(petrinet::AbstractPetriNet) #TODO move "lvector tools" section
    net = pnmlnet(petrinet)
    LVector((;[arc_id => inscription(a) for (arc_id, a) in pairs(arcdict(net))]...))
end

"""
    rates(petrinet::AbstractPetriNet) -> LVector[id(transition) => rate(transition]

Return a transition-id labelled vector of rate values.

We allow all PNML nets to be stochastic Petri nets. See [`rate`](@ref).
"""
function rates(petrinet::AbstractPetriNet) #TODO move "lvector tools" section
    net = pnmlnet(petrinet)
    LVector((;[tid => rate(t) for (tid, t) in pairs(transitiondict(net))]...))
end


"""
    initial_markings(petrinet) -> LVector{marking_value_type(pntd)}

LVector labelled with place id and holding initial marking's value.
"""
function initial_markings(petrinet::AbstractPetriNet) #TODO move "lvector tools" section
    net = pnmlnet(petrinet)
    m1 = LVector((;[id => initial_marking(p)() for (id,p) in pairs(placedict(net))]...))
    return m1
end

"""
    conditions(petrinet) -> LVector{condition_value_type(pntd)}

LVector labelled with transition id and holding its condition's value.
"""
function conditions(petrinet::AbstractPetriNet) #TODO move "lvector tools" section
    net = pnmlnet(petrinet)
    LVector((;[id => condition(t) for (id, t) in pairs(transitiondict(net))]...))
end

#####################################################################################
#
#####################################################################################

#-----------------------------------------------------------------
#=
Given x ∈ S ∪ T
  - the set •x = {y | (y, x) ∈ F } is the preset of x.
  - the set x• = {y | (x, y) ∈ F } is the postset of x.
=#
"""
Iterate ids of input (arc source) for output transition or place `id`.

See [`in_inscriptions`](@ref) and [`transition_function`](@ref).
"""
preset(net, id) = Iterators.map(source, tgt_arcs(net, id))

"""
    postset(net, id) -> Iterator

Iterate ids of output (arc target) for source transition or place `id`.

See [`out_inscriptions`](@ref) and [`transition_function`](@ref).
"""
postset(net, id) = Iterators.map(target, src_arcs(net, id))

"""
    input_matrix(petrinet::AbstractPetriNet) -> Matrix{inscription_value_type(net)}

Create and return a matrix ntransitions x nplaces
"""
function input_matrix(petrinet::AbstractPetriNet)
    net = pnmlnet(petrinet)
    imatrix = Matrix{inscription_value_type(net)}(undef,
                                                  ntransitions(net),
                                                  nplaces(net))
    return input_matrix!(imatrix, net) # fill the matrix & return it
end

function input_matrix!(imatrix, net)
    for (p, place_id) in enumerate(place_idset(net))
        for (t, transition_id) in enumerate(transition_idset(net))
            a = arc(net, place_id, transition_id)
            imatrix[t,p] = isnothing(a) ? zero(inscription_value_type(net)) : inscription(a)
        end
    end
    return imatrix
 end

"""
    output_matrix(petrinet::AbstractPetriNet) -> Matrix{inscription_value_type(net)}
"""
function output_matrix(petrinet::AbstractPetriNet)
    net = pnmlnet(petrinet)
    omatrix = Matrix{inscription_value_type(net)}(undef,
                                                  ntransitions(net),
                                                  nplaces(net))
    return output_matrix!(omatrix, net) # fill the matrix & return it
end

function output_matrix!(omatrix, net)
    for (t,transition_id) in enumerate(transition_idset(net))
        for (p, place_id) in enumerate(place_idset(net))
            a = arc(net, transition_id, place_id)
            omatrix[t, p] = isnothing(a) ? zero(inscription_value_type(net)) : inscription(a)
        end
    end
    return omatrix
end

"""
    incidence_matrix(petrinet) -> LArray

C[transition,place] = inscription(transition,place) - inscription(place,transition)
"""
function incidence_matrix(petrinet::AbstractPetriNet)
    net = pnmlnet(petrinet)
    #TODO  Make Labelled Matrix? ComponentArray?
    C = Matrix{Int}(undef, ntransitions(net), nplaces(net)) #Preallocate storage
    z = zero(Int) # continuous would use float64
    @assert z isa Number
    for (t, transition_id) in enumerate(transition_idset(net))
        for (p, place_id) in enumerate(place_idset(net))
            tp = arc(net, transition_id, place_id)
            l = if isnothing(tp)
                z
            else
                inscription(tp)::Number
            end

            pt = arc(net, place_id, transition_id)
            r = if isnothing(pt)
                z
            else
                inscription(pt)::Number
            end

            #c = (isnothing(tp) ? z : inscription(tp)) - (isnothing(pt) ? z : inscription(pt))

            #! inscription(arc) can return HLInscription or Inscription
            #! which have values of PnmlMultiset or Number.

            c = l - r
            C[t, p] = c
        end
    end
    return C
end

"""
    enabled(::AbstractPetriNet, ::LVector) -> LVector

Returns labelled vector of id=>boolean where `true` means transitionid is enabled at marking.
"""
function enabled(petrinet::AbstractPetriNet, marking) #TODO move "lvector tools" section
    net = pnmlnet(petrinet)
    LVector((;[t => all(p -> marking[p] >= inscription(arc(net,p,t)), preset(net, t)) for t in transition_idset(net)]...))
end

"""
    fire!(incidence, enabled, marking) -> LVector

Return the marking after firing transition:   marking + incidence * enabled

`marking` LVector values added to product of `incidence'` matrix and firing vector `enabled`.
"""
function fire!(incidence, enabled, m₀) #TODO move "lvector tools" section
    m₁ = muladd(incidence', enabled, m₀)
    LVector(namedtuple(symbols(m₀), m₁))
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
        length(arcs(pn)), " arcs")::String
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

#-----------------------------------------------------------------
#-----------------------------------------------------------------

"""
Wrap a single pnml net. Presumes that the net does not need to be flattened
as all content is in first page.

$(TYPEDEF)
$(TYPEDFIELDS)

# Details

"""
struct HLPetriNet{PNTD} <: AbstractPetriNet{PNTD}
    net::PnmlNet{PNTD}
end
"Construct from string of valid pnml XML, using the first network in model."
HLPetriNet(str::AbstractString) = HLPetriNet(parse_str(str))
HLPetriNet(model::PnmlModel)    = HLPetriNet(first(nets(model)))

#=
# What are the characteristics of a SimpleNet?

This use-case is for explorations, might abuse the standard. The goal of PNML.jl
is to not constrain what can be parsed & represented in the
intermediate representation (IR). So many non-standard XML constructions are possible,
with the standars being a subset. It is the role of IR users to enforce semantics
upon the IR. SimpleNet takes liberties!

Assumptions about labels:
 place has numeric marking, default 0
 transition has numeric condition, default 0
 arc has source, target, numeric inscription value, default 0

# Non-simple Networks means what?

# SimpleNet

Created to be a end-to-end use case. And explore implementing something-that-works
while building upon and improving the IR. Does not try to conform to any standard.
Much of the complexity possible with pnml is ignored.

The first use is to recreate the lotka-volterra model from Petri.jl examples.
Find it in the examples folder. This is a stochastic net or reaction net.

Liberties are taken with pnml, remember that standards-checking is not a goal.
A less-simple consumer of the IR can impose standards-checking.

=#

"""
$(TYPEDEF)
$(TYPEDFIELDS)

**TODO: Rename SimpleNet to TBD**

SimpleNet is a concrete `AbstractPetriNet` wrapping a single `PnmlNet`.

Uses a flattened net to avoid the page level of the pnml hierarchy.

Note: A multi-page petri net can always be flattened by removing
referenceTransitions & referencePlaces, and merging pages into the first page.
"""
struct SimpleNet{PNTD} <: AbstractPetriNet{PNTD}
    id::Symbol # Redundant copy of the net's ID for dispatch.
    net::PnmlNet{PNTD}
end

SimpleNet(s::AbstractString) = SimpleNet(parse_str(s))
SimpleNet(node::XMLNode)     = SimpleNet(parse_pnml(node))
function SimpleNet(model::PnmlModel)
    ns = nets(model)
    fn = first(ns)
    SimpleNet(fn)
end
function SimpleNet(net::PnmlNet)
    flatten_pages!(net)
    SimpleNet(pid(net), net)
end

#-------------------------------------------------------------------------------
# Implement PNML Petri Net interface. See interface.jl for docstrings.
#-------------------------------------------------------------------------------
