"""
$(TYPEDEF)

Top-level of a **single network** in a pnml model that is some flavor of Petri Net. 
Note that pnml can represent nets that are not Petri Nets.
Here is where specialization and restriction are applied to achive Proper Petri Behavior.

See [`PnmlModel`](@ref), [`PnmlType`](@ref).

# Extended

Additional constrants can be imposed. We want to run under the motto:
"syntax is not semantics, quack".

Since a PNML.Document can contain multiple networks it is possible that a higher-level
will create multiple PetriNet instances, each a different subtype.

Multiple [`Page`](@ref) can (are permitted to) be merged into one page 
by [`flatten_pages!`](@ref) without losing any Petri Net semantics.
Initial concrete `PetriNet`s are constructed by flattening to a single `Page`.
"""
abstract type PetriNet{PNTD<:PnmlType} end

# Example of the idiom of handling the three "top level" components.
# Usually in the form of a cascade, without type parameters.
nettype(petrinet::PetriNet{T}) where {T <: PnmlType} = T
nettype(::PnmlNet{T}) where {T <: PnmlType} = T
nettype(::Page{T}) where {T <: PnmlType} = T

nettype(::Place{T}) where {T <: PnmlType} = T
nettype(::Transition{T}) where {T <: PnmlType} = T
nettype(::Arc{T}) where {T <: PnmlType} = T

using Base: Fix2
"""
$(TYPEDSIGNATURES)
Return function to be used like: any(ispid(sym), iterate_with_pid)
"""
ispid(x) = Fix2(===, x)

#------------------------------------------------------------------------------------------
# Methods that should be implemented by concrete subtypes of PetriNet will throw an error.
#------------------------------------------------------------------------------------------

pid(::PetriNet) = error("must implement id accessor")
pages(::PetriNet) = error("not implemented")

places(::PetriNet) = error("not implemented")
transitions(::PetriNet) = error("not implemented")
arcs(::PetriNet) = error("not implemented")
refplaces(::PetriNet) = error("not implemented")
reftransitions(::PetriNet) = error("not implemented")

# Presumes net has been flattened. Or in a future implementation, collect from all pages. 
places(net::PnmlNet)         = places(pages(net)[begin])
transitions(net::PnmlNet)    = transitions(pages(net)[begin])
arcs(net::PnmlNet)           = arcs(pages(net)[begin])
refplaces(net::PnmlNet)      = refplaces(pages(net)[begin])
reftransitions(net::PnmlNet) = reftransitions(pages(net)[begin])

# Handle individual pages here.
places(net::PnmlNet, page_idx)         = places(pages(net)[page_idx])
transitions(net::PnmlNet, page_idx)    = transitions(pages(net)[page_idx])
arcs(net::PnmlNet, page_idx)           = arcs(pages(net)[page_idx])
refplaces(net::PnmlNet, page_idx)      = refplaces(pages(net)[page_idx])
reftransitions(net::PnmlNet, page_idx) = reftransitions(pages(net)[page_idx])

places(page::Page)         = page.places
transitions(page::Page)    = page.transitions
arcs(page::Page)           = page.arcs
refplaces(page::Page)      = page.refPlaces
reftransitions(page::Page) = page.refTransitions

#------------------------------------------------------------------
# PLACES, MARKING,
#------------------------------------------------------------------

has_place(petrinet::PetriNet, id::Symbol) = any(x -> pid(x) === id, places(petrinet))
has_place(net::PnmlNet, id::Symbol) = has_place(net.pages[begin], id)
has_place(net::PnmlNet, id::Symbol, page_idx) = has_place(net.pages[page_idx], id)
has_place(page::Page, id::Symbol) = any(x -> pid(x) === id, places(page))

place(petrinet::PetriNet, id::Symbol) = getfirst(x -> pid(x) === id, places(petrinet))
place(net::PnmlNet, id::Symbol) = place(net.pages[begin], id)
place(net::PnmlNet, id::Symbol, page_idx) = place(net.pages[page_idx], id)
place(page::Page, id::Symbol) = getfirst(x -> pid(x) === id, places(page))

place_ids(petrinet::PetriNet) = map(pid, places(petrinet))
place_ids(net::PnmlNet) = place_ids(net.pages[begin])
place_ids(net::PnmlNet, page_idx) = place_ids(net.pages[page_idx])
place_ids(page::Page) = map(pid, places(page))


marking(petrinet::PetriNet, placeid::Symbol) = marking(place(petrinet, placeid))
marking(net::PnmlNet) = marking(net.pages[begin], placeid)
marking(net::PnmlNet, placeid::Symbol, page_idx) = marking(net.pages[page_idx], placeid)
marking(page::Page, placeid::Symbol) = marking(place(page, placeid))

#TODO Use marking (initialized to initialMarking in constructor).
# Return all places' marking as LVector
initialMarking(petrinet::PetriNet)     = initialMarking(petrinet.net)
initialMarking(net::PnmlNet)           = initialMarking(net.pages[begin])
initialMarking(net::PnmlNet, page_idx) = initialMarking(net.pages[page_idx])
initialMarking(page::Page)             = initialMarking(page, place_ids(page))
initialMarking(page::Page, id_vec::Vector{Symbol}) = 
                                LVector((;[p=>marking(page, p)() for p in id_vec]...))

#------------------------------------------------------------------
# TRANSITIONS, CONDITIONS
#------------------------------------------------------------------

transition_ids(petrinet::PetriNet)     = transition_ids(petrinet.net)
transition_ids(net::PnmlNet,)          = transition_ids(net.pages[begin])
transition_ids(net::PnmlNet, page_idx) = transition_ids(net.pages[page_idx])
transition_ids(page::Page)             = map(pid, page.transitions)

has_transition(petrinet::PetriNet, id::Symbol)     = has_transition(petrinet.net, id)
has_transition(net::PnmlNet, id::Symbol)           = has_transition(net.pages[begin], id)
has_transition(net::PnmlNet, id::Symbol, page_idx) = has_transition(net.pages[page_idx], id)
has_transition(page::Page, id::Symbol)             = any(ispid(id), transition_ids(page))

transition(petrinet::PetriNet, id::Symbol)     = transition(petrinet.net, id)
transition(net::PnmlNet, id::Symbol)           = transition(net.pages[begin], id)
transition(net::PnmlNet, id::Symbol, page_idx) = transition(net.pages[page_idx], id)
transition(page::Page, id::Symbol)             = getfirst(x->pid(x)===id, transitions(page))

condition(petrinet::PetriNet, trans_id::Symbol)     = condition(petrinet.net, trans_id)
condition(net::PnmlNet, trans_id::Symbol)           = condition(net.pages[begin], trans_id)
condition(net::PnmlNet, trans_id::Symbol, page_idx) = condition(net.pages[page_idx], trans_id)
condition(page::Page, trans_id::Symbol)             = condition(transition(page, trans_id))

#----------------------------------------
conditions(petrinet::PetriNet)     = conditions(petrinet.net)
conditions(net::PnmlNet)           = conditions(net.pages[begin])
conditions(net::PnmlNet, page_idx) = conditions(net.pages[page_idx])
conditions(page::Page)             = conditions(page, transition_ids(page))

conditions(page::Page, idvec::Vector{Symbol}) = LVector((;[t=>condition(page, t) for t in idvec]...))

#------------------------------------------------------------------
# ARC, INSCRIPTION
#------------------------------------------------------------------

arc_ids(petrinet::PetriNet)     = arc_ids(petrinet.net)
arc_ids(net::PnmlNet)           = arc_ids(pages(net)[begin])
arc_ids(net::PnmlNet, page_idx) = arc_ids(pages(net)[page_idx])
arc_ids(page::Page)             = map(pid, arcs(page))

has_arc(petrinet::PetriNet, id::Symbol)     = has_arc(petrinet.net, id)
has_arc(net::PnmlNet, id::Symbol)           = has_arc(pages(net)[begin], id)
has_arc(net::PnmlNet, id::Symbol, page_idx) = has_arc(pages(net)[page_idx], id)
has_arc(page::Page, id::Symbol)             = any(ispid(id), arc_ids(page))

arc(petrinet::PetriNet, id::Symbol)     = arc(petrinet.net, id)
arc(net::PnmlNet, id::Symbol)           = arc(pages(net)[begin], id)
arc(net::PnmlNet, id::Symbol, page_idx) = arc(pages(net)[page_idx], id)
arc(page::Page, id::Symbol)             = getfirst(x->pid(x)===id, arcs(page))

all_arcs(petrinet::PetriNet, id::Symbol)     = all_arcs(petrinet.net, id)
all_arcs(net::PnmlNet, id::Symbol)           = all_arcs(pages(net)[begin], id)
all_arcs(net::PnmlNet, id::Symbol, page_idx) = all_arcs(pages(net)[page_idx], id)
all_arcs(page::Page, id::Symbol)             = filter(a -> source(a)===id || target(a)===id, arcs(page))

src_arcs(petrinet::PetriNet, id::Symbol)     = src_arcs(petrinet.net, id)
src_arcs(net::PnmlNet, id::Symbol)           = src_arcs(pages(net)[begin], id)
src_arcs(net::PnmlNet, id::Symbol, page_idx) = src_arcs(pages(net)[page_idx], id)
src_arcs(page::Page, id::Symbol)             = filter(a -> source(a)===id, arcs(page))

tgt_arcs(petrinet::PetriNet, id::Symbol)     = tgt_arcs(petrinet.net, id)
tgt_arcs(net::PnmlNet, id::Symbol)           = tgt_arcs(pages(net)[begin], id)
tgt_arcs(net::PnmlNet, id::Symbol, page_idx) = tgt_arcs(pages(net)[page_idx], id)
tgt_arcs(page::Page, id::Symbol)             = filter(a -> target(a)===id, arcs(page))

inscription(petrinet::PetriNet, arc_id::Symbol)     = inscription(petrinet.nets, arc_id)
inscription(net::PnmlNet, arc_id::Symbol)           = inscription(pages(net)[begin], arc_id)
inscription(net::PnmlNet, arc_id::Symbol, page_idx) = inscription(pages(net)[page_idx], arc_id)
inscription(page::Page, arc_id::Symbol)             = inscription(arc(page, arc_id))

#------------------------------------------------------------------
# REFERENCES
#------------------------------------------------------------------

has_refP(petrinet::PetriNet, ref_id::Symbol)     = has_refP(petrinet.net, ref_id)
has_refP(net::PnmlNet, ref_id::Symbol)           = has_refP(pages(net)[begin], ref_id)
has_refP(net::PnmlNet, ref_id::Symbol, page_idx) = has_refP(pages(net)[page_idx], ref_id)
has_refP(page::Page, ref_id::Symbol)             = any(x -> pid(x) === ref_id, refplaces(page))

has_refT(petrinet::PetriNet, ref_id::Symbol)     = has_refP(petrinet.net, ref_id)
has_refT(net::PnmlNet, ref_id::Symbol)           = has_refP(pages(net)[begin], ref_id)
has_refT(net::PnmlNet, ref_id::Symbol, page_idx) = has_refP(pages(net)[page_idx], ref_id)
has_refT(page::Page, ref_id::Symbol)             = any(x -> pid(x) === ref_id, reftransitions(page))

refplace_ids(petrinet::PetriNet)     = refplace_ids(petrinet.net)
refplace_ids(net::PnmlNet)           = refplace_ids(net.pages[begin])
refplace_ids(net::PnmlNet, page_idx) = refplace_ids(net.pages[page_idx])
refplace_ids(page::Page)             = map(pid, page.refPlaces)

reftransition_ids(petrinet::PetriNet)     = reftransition_ids(petrinet.net)
reftransition_ids(net::PnmlNet)           = reftransition_ids(net.pages[begin])
reftransition_ids(net::PnmlNet, page_idx) = reftransition_ids(net.pages[page_idx])
reftransition_ids(page::Page)             = map(pid, page.refTransitions)

refplace(petrinet::PetriNet, id::Symbol)     = refplace(petrinet.net, id)
refplace(net::PnmlNet, id::Symbol)           = refplace(net.pages[begin], id)
refplace(net::PnmlNet, id::Symbol, page_idx) = refplace(net.pages[page_idx], id)
refplace(page::Page, id::Symbol)             = getfirst(x -> pid(x) === id, refplaces(page))

reftransition(petrinet::PetriNet, id::Symbol)     = reftransition(petrinet.net, id)
reftransition(net::PnmlNet, id::Symbol)           = reftransition(net.pages[begin], id)
reftransition(net::PnmlNet, id::Symbol, page_idx) = reftransition(net.pages[page_idx], id)
reftransition(page::Page, id::Symbol)             = getfirst(x -> pid(x) === id, reftransitions(page))

#-----------------------------------------------------------------
#-----------------------------------------------------------------
"""
$(TYPEDSIGNATURES)

Transition function of a Petri Net.
Each transition has an input vector and an output vector.
Each labelled vector is indexed by the place on the other end of the arc.
Values are inscriptions of the arc.
"""
function transition_function end

transition_function(petrinet::PetriNet)     = transition_function(petrinet.net)
transition_function(net::PnmlNet)           = transition_function(net.pages[begin])
transition_function(net::PnmlNet, page_idx) = transition_function(net.pages[page_idx])
transition_function(page::Page) = transition_function(page, transition_ids(page))
transition_function(page::Page, idvec::Vector{Symbol}) = 
                                LVector((;[t=>in_out(page, t) for t in idvec]...))

"""
$(TYPEDSIGNATURES)

Return tuple of input, output labelled vectors with key of place ids and
value of arc inscription's value for use as a transition function.
#TODO When do these get called "pre" and "post"?
"""
function in_out end

in_out(petrinet::PetriNet, transition_id::Symbol)     = in_out(petrinet.net, transition_id)
in_out(net::PnmlNet, transition_id::Symbol)           = in_out(net.pages[begin], transition_id)
in_out(net::PnmlNet, transition_id::Symbol, page_idx) = in_out(net.pages[page_idx], transition_id)
in_out(page::Page, transition_id::Symbol) = (ins(page, transition_id), outs(page, transition_id))

"""
$(TYPEDSIGNATURES)
Return arcs of `p` that have `transition_id` as the target.
"""
function ins(p, transition_id::Symbol)
    LVector( (; [source(a)=>inscription(a) for a in tgt_arcs(p, transition_id)]...))
end

"""
$(TYPEDSIGNATURES)
Return arcs of `p` that have `transition_id` as the source.
"""
function outs(p, transition_id::Symbol)
    #isempty(src_arcs(p, transition_id)) && @warn "no src_arcs for $transition_id"
    LVector( (; [target(a)=>inscription(a) for a in src_arcs(p, transition_id)]...))
end

#------------------------------------------------------------------
#
#------------------------------------------------------------------

