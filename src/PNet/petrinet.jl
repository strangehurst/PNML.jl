using Base: Fix2, Fix1
#=
=====================================================================================
2025-05-01 Consider a declarative API to define different nets.

Tool Info Parsers: from an `(XLNode, PnmlType)` parse well-formed XML into a `ToolInfo`.
    What type is returned? `Vector{AnyElement}` is the default.
    `TokenGraphics` is defined in ISO/IEC 15909-2:2011 for `PTNets`.
    Some run-time dispatch expected during parsing phase.
    Returned value will be accessed from enclosing object. #TODO API
    Enclosing object will have a collection of `ToolInfo` objects.
    AnyElement from fallback parer is from the XMLDict parser.
    Registering a parser provides a toolname, version and `ToolParser`.
    When a `<toolspecific>` tag is found only registered parsers are used (first match?).
    The registered parsers return a PNML object that may be different from AnyElement. #TODO
    Users find the `ToolInfo` from toolname, version regular expression matches.
    Users are expected to know how to deal with the `ToolInfo{T}}` type parameter.
    We can define infrastructure for these parsers. #TODO API
    #todo! add NUPN API see https://mcc.lip6.fr/2025/nupn.php

Label Parsers:
    There are 2 levels of Labels in PNML: core/PTNet, High-Level.
    In core the labels use `<text>` for meaning, while
    in HL the labels use `<structure>` for meaning.
    Keep the tag semantics consistent.

=====================================================================================
=#


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
by [`PNML.flatten_pages!`](@ref) without losing any Petri Net semantics.
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
pid(petrinet::AbstractPetriNet)     = PNML.pid(pnmlnet(petrinet))
pnmlnet(petrinet::AbstractPetriNet) = petrinet.net

# #------------------------------------------------------------------------------------------
# # Forward MANY THINGS to the IR implementation pnmlnet.
# # TODO Adopt a forwarder?
# # ! TODO SEE if there is a need for much forwarding.
# #------------------------------------------------------------------------------------------
# name(petrinet::AbstractPetriNet)           = PNML.name(pnmlnet(petrinet))
# places(petrinet::AbstractPetriNet)         = PNML.places(pnmlnet(petrinet))
# transitions(petrinet::AbstractPetriNet)    = PNML.transitions(pnmlnet(petrinet))
# arcs(petrinet::AbstractPetriNet)           = PNML.arcs(pnmlnet(petrinet))
# refplaces(petrinet::AbstractPetriNet)      = PNML.refPlaces(pnmlnet(petrinet))
# reftransitions(petrinet::AbstractPetriNet) = PNML.refTransitions(pnmlnet(petrinet))

# npages(pn::AbstractPetriNet)          = PNML.npages(pnmlnet(pn))
# nplaces(pn::AbstractPetriNet)         = PNML.nplaces(pnmlnet(pn))
# ntransitions(pn::AbstractPetriNet)    = PNML.ntransitions(pnmlnet(pn))
# narcs(pn::AbstractPetriNet)           = PNML.narcs(pnmlnet(pn))
# nrefplaces(pn::AbstractPetriNet)      = PNML.nrefplaces(pnmlnet(pn))
# nreftransitions(pn::AbstractPetriNet) = PNML.nreftransitions(pnmlnet(pn))

# #------------------------------------------------------------------
# "Return pnmlnet's place_idset"
# place_idset(petrinet::AbstractPetriNet)           = PNML.place_idset(pnmlnet(petrinet))
# has_place(petrinet::AbstractPetriNet, id::Symbol) = PNML.has_place(pnmlnet(petrinet), id)
# place(petrinet::AbstractPetriNet, id::Symbol)     = PNML.place(pnmlnet(petrinet), id)

# initial_marking(petrinet::AbstractPetriNet, id::Symbol) = PNML.initial_marking(pnmlnet(petrinet), id)

# #------------------------------------------------------------------
# transition_idset(petrinet::AbstractPetriNet)           = PNML.transition_idset(pnmlnet(petrinet))
# has_transition(petrinet::AbstractPetriNet, id::Symbol) = PNML.has_transition(pnmlnet(petrinet), id)
# transition(petrinet::AbstractPetriNet, id::Symbol)     = PNML.transition(pnmlnet(petrinet), id)

# condition(petrinet::AbstractPetriNet, id::Symbol)      = PNML.condition(pnmlnet(petrinet), id)

# #------------------------------------------------------------------
# arc_idset(petrinet::AbstractPetriNet)            = PNML.arc_idset(pnmlnet(petrinet))
# has_arc(petrinet::AbstractPetriNet, id::Symbol)  = PNML.has_arc(pnmlnet(petrinet), id)
# arc(petrinet::AbstractPetriNet, id::Symbol)      = PNML.arc(pnmlnet(petrinet), id)

# all_arcs(petrinet::AbstractPetriNet, id::Symbol) = PNML.all_arcs(pnmlnet(petrinet), id)
# src_arcs(petrinet::AbstractPetriNet, id::Symbol) = PNML.src_arcs(pnmlnet(petrinet), id)
# tgt_arcs(petrinet::AbstractPetriNet, id::Symbol) = tPNML.gt_arcs(pnmlnet(petrinet), id)

# "Forward inscription lookup to `pnmlnet`"
# inscription(petrinet::AbstractPetriNet, arc_id::Symbol) = PNML.inscription(pnmlnet(petrinet), arc_id)

# #------------------------------------------------------------------
# refplace_idset(petrinet::AbstractPetriNet)            = PNML.refplace_idset(pnmlnet(petrinet))
# has_refplace(petrinet::AbstractPetriNet, id::Symbol)  = PNML.has_refplace(pnmlnet(petrinet), id)
# refplace(petrinet::AbstractPetriNet, id::Symbol)      = PNML.refplace(pnmlnet(petrinet), id)

# reftransition_idset(petrinet::AbstractPetriNet)       = PNML.reftransition_idset(pnmlnet(petrinet))
# has_reftransition(petrinet::AbstractPetriNet, id::Symbol) = PNML.has_reftransition(pnmlnet(petrinet), id)
# reftransition(petrinet::AbstractPetriNet, id::Symbol) = PNML.reftransition(pnmlnet(petrinet), id)


#####################################################################################
# Labelled Vectors
#####################################################################################

"""
    inscriptions(petrinet::AbstractPetriNet) -> LVector[pid(arc) => inscription(arc)]
"""
function inscriptions end #TODO! non-ground terms
inscriptions(petrinet::AbstractPetriNet) = LVector(; collect(PNML.inscriptions(pnmlnet(petrinet)))...)

function conditions end #TODO! non-ground terms
conditions(petrinet::AbstractPetriNet)  = LVector(; collect(conditions(pnmlnet(petrinet)))...)



"""
    rates(petrinet::AbstractPetriNet) -> LVector[id(transition) => rate_value(transition)]

Return a transition-id labelled vector of rate values.

We allow all PNML nets to be stochastic Petri nets. See [`rate_value`](@ref).
"""
function rates(petrinet::AbstractPetriNet) #TODO move "lvector tools" section
    net = pnmlnet(petrinet)
    LVector((;[tid => rate_value(t) for (tid, t) in pairs(PNML.transitiondict(net))]...))
end
# rate label implements the PnmlLabel interface.
# Provides a method that accepts a "label owning" object (PnmlNet, AbstractObject).
# Method returns TODO! add traits to identify type? Whomever calls this method

"""
    initial_markings(petrinet) -> LVector{marking_value_type}

LVector labelled with place id and holding initial marking's value.
Used to create a vector of place markings indexed by place ID.

#TODO refactor from LVector to tuples of pairs.

High-level P/T Nets use cardinality of its multiset place marking value.
Really, the implementation should be the same as for PTNet.

Other HL Nets use multisets.
"""
function initial_markings end #TODO move "lvector tools" section

initial_markings(petrinet::AbstractPetriNet) = initial_markings(pnmlnet(petrinet))

function initial_markings(net::PnmlNet)
    LVector((;[id => initial_marking(p)::Number for (id,p) in pairs(PNML.placedict(net))]...))
end

# PT_HLPNG multisets of dotconstants map well to integer via cardinality.
function initial_markings(net::PnmlNet{PT_HLPNG})
    LVector((;[id => PNML.cardinality(initial_marking(p)::PnmlMultiset)::Number for (id,p) in pairs(PNML.placedict(net))]...))
end

#! Other HL need it to be treated as multiset, not simple numbers!
function initial_markings(net::PnmlNet{<:AbstractHLCore})
    # Evaluate the ground term expression into a multiset.
    LVector((;[id => initial_marking(p)::PnmlMultiset for (id,p) in pairs(PNML.placedict(net))]...))
end

#####################################################################################
#
#####################################################################################


#-----------------------------------------------------------------
# Show and Tell Section:
#-----------------------------------------------------------------
Base.summary(io::IO, pn::AbstractPetriNet) = print(io, summary(pn))
function Base.summary(pn::AbstractPetriNet)
    string(typeof(pn), " id ", PNet.pid(pn), ", ",
        length(PNML.places(pn.net)), " places, ",
        length(PNML.transitions(pn.net)), " transitions, ",
        length(PNML.arcs(pn.net)), " arcs")::String
end

function Base.show(io::IO, pn::AbstractPetriNet)
    println(io, summary(pn))
    println(io, "places")
    println(io, PNML.places(pn.net))
    println(io, "transitions")
    println(io, PNML.transitions(pn.net))
    println(io, "arcs")
    print(io, PNML.arcs(pn.net))
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
    ctx::Context
    net::PnmlNet{PNTD}
end
"Construct from string of valid pnml XML, using the first network in model."
HLPetriNet(ctx::Context, str::AbstractString) = HLPetriNet(ctx, pnmlmodel(ctx, xmlroot(str); tp_vec=ToolParser[], lp_vec=LabelParser[]))
HLPetriNet(ctx::Context, model::PnmlModel)    = HLPetriNet(ctx, first(nets(model)))

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
    metadata::Any #
end

# Method Cascade.
# First two run the parser and can have addded tool and label plugins as context.
# tools => (tool1, [tool2,]...), labels =< (label1, [label2,]...)
SimpleNet(s::AbstractString; context...)  = SimpleNet(xmlroot(s); context...)
SimpleNet(node::PNML.XMLNode; context...) = SimpleNet(PNML.Parser.pnmlmodel(node; context...))

# These two use the flattened 1st net of the PnmlModel.
SimpleNet(model::PnmlModel; metadata=nothing) = SimpleNet(first(PNML.nets(model)); metadata)
function SimpleNet(net::PnmlNet; metadata=nothing)
    PNML.flatten_pages!(net)
    SimpleNet(PNML.pid(net), net, metadata)
end

#-------------------------------------------------------------------------------
# Implement PNML Petri Net interface. See interface.jl for docstrings.
#-------------------------------------------------------------------------------
