"""
Provides 2nd-level parsing of the intermediate representation
of a  **single network** in a pnml model.
See [`PnmlModel`](@ref).

$(TYPEDEF)

# Extended

The type parameter of a nets should map directly and simply
to subtypes of [`PnmlType`](@ref).

Additional constrants can be imposed. We want to run under the motto:
"syntax is not semantics, quack".

Since a PNML.Document can contain multiple networks it is possible that a higher-level
will create multiple PetriNet instances, each a different subtype.

Multiple [`Page`](@ref) can (are permitted) be merged into one page 
by [`flatten_pages!`](@ref) without losing any Petri Net semantics.
Initial concrete `PetriNet`s are constructed by flattening to a single `Page`.
"""
abstract type PetriNet{T<:PnmlType} end

nettype(petrinet::N) where {T <: PnmlType, N <: PetriNet{T}} = T

nettype(::PnmlNet{T}) where {T <: PnmlType} = T
nettype(::Page{T}) where {T <: PnmlType} = T
nettype(::Place{T}) where {T <: PnmlType} = T
nettype(::Transition{T}) where {T <: PnmlType} = T
nettype(::Arc{T}) where {T <: PnmlType} = T

nettype(::Type{PnmlNet{T}}) where {T <: PnmlType} = T
nettype(::Type{Page{T}}) where {T <: PnmlType} = T
nettype(::Type{Place{T}}) where {T <: PnmlType} = T
nettype(::Type{Transition{T}}) where {T <: PnmlType} = T
nettype(::Type{Arc{T}}) where {T <: PnmlType} = T

#------------------------------------------------------------------
# Methods that should be implemented by concrete subtypes.
#------------------------------------------------------------------

pid(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} = error("must implement id accessor")
pages(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} = error("not implemented")

places(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} = error("not implemented")
transitions(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} = error("not implemented")
arcs(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} = error("not implemented")
refplaces(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} = error("not implemented")
reftransitions(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} = error("not implemented")

places(net::PnmlNet, page_idx=1) = places(pages(net)[page_idx])
transitions(net::PnmlNet, page_idx=1) = transitions(pages(net)[page_idx])
arcs(net::PnmlNet, page_idx=1) = arcs(pages(net)[page_idx])
refplaces(net::PnmlNet, page_idx=1) = refplaces(pages(net)[page_idx])
reftransitions(net::PnmlNet, page_idx=1) = reftransitions(pages(net)[page_idx])

places(page::Page) = page.places
transitions(page::Page) = page.transitions
arcs(page::Page) = page.arcs
refplaces(page::Page) = page.refPlaces
reftransitions(page::Page) = page.refTransitions

#------------------------------------------------------------------
# ARC, INSCRIPTION
#------------------------------------------------------------------

function has_arc(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    any(x -> pid(x) === id, arcs(petrinet))
end
function arc(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    getfirst(x -> pid(x) === id, arcs(petrinet))
end
arc_ids(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} = map(pid, arcs(petrinet))
function all_arcs(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    filter(a -> source(a)===id || target(a)===id, arcs(petrinet))
end
function src_arcs(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    filter(a -> source(a)===id, arcs(petrinet))
end
function tgt_arcs(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    filter(a -> target(a)===id, arcs(petrinet))
end
function inscription(petrinet::N, arc_id::Symbol) where {T <: PnmlType, N <: PetriNet{T}}
    inscription(arc(petrinet, arc_id))
end

has_arc(net::PnmlNet, id::Symbol, page_idx=1) = has_arc(pages(net)[page_idx], id)
arc(net::PnmlNet, id::Symbol, page_idx=1) = arc(pages(net)[page_idx], id)
arc_ids(net::PnmlNet, page_idx=1) = arc_ids(pages(net)[page_idx])
all_arcs(net::PnmlNet, id::Symbol, page_idx=1) = all_arcs(pages(net)[page_idx], id)
src_arcs(net::PnmlNet, id::Symbol, page_idx=1) = src_arcs(pages(net)[page_idx], id)
tgt_arcs(net::PnmlNet, id::Symbol, page_idx=1) = tgt_arcs(pages(net)[page_idx], id)
inscription(net::PnmlNet, arc_id::Symbol, page_idx=1) = inscription(pages(net)[page_idx], arc_id)

has_arc(page::Page, id::Symbol) = any(x -> pid(x) === id, arcs(page))
arc(page::Page, id::Symbol) = getfirst(x -> pid(x) === id, arcs(page))
arc_ids(page::Page) = map(pid, arcs(page))
all_arcs(page::Page, id::Symbol) = filter(a -> source(a)===id, arcs(page))
src_arcs(page::Page, id::Symbol) = filter(a -> source(a)===id, arcs(page))
tgt_arcs(page::Page, id::Symbol) = filter(a -> source(a)===id, arcs(page))
inscription(page::Page, arc_id::Symbol) = inscription(arc(page, arc_id))

#------------------------------------------------------------------
# REFERENCES
#------------------------------------------------------------------

function has_refP(petrinet::N, ref_id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    any(x -> pid(x) === ref_id, refplaces(petrinet))
end
function has_refT(petrinet::N, ref_id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    any(x -> pid(x) === ref_id, reftransitions(petrinet))
end
refplace_ids(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} =
    map(pid, refplaces(petrinet))
reftransition_ids(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} =
    map(pid, reftransitions(petrinet))
function refplace(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    refplace(petrinet.net, id)
end
function reftransition(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    reftransition(petrinet.net, id)
end
    
has_refP(net::PnmlNet, ref_id::Symbol, page_idx=1) = has_refP(pages(net)[page_idx], ref_id)
has_refT(net::PnmlNet, ref_id::Symbol, page_idx=1) = has_refP(pages(net)[page_idx], ref_id)
refplace_ids(net::PnmlNet, page_idx=1) = refplace_ids(net.pages[page_idx])
reftransition_ids(net::PnmlNet, page_idx=1) = reftransition_ids(net.pages[page_idx])
refplace(net::PnmlNet, id::Symbol, page_idx=1) = refplace(net.pages[page_idx], id)
reftransition(net::PnmlNet, id::Symbol, page_idx=1) = reftransition(net.pages[page_idx], id)

has_refP(page::Page, ref_id::Symbol) = any(x -> pid(x) === ref_id, refplaces(page))
has_refT(page::Page, ref_id::Symbol) = any(x -> pid(x) === ref_id, reftransitions(page))
refplace_ids(page::Page) = map(pid, page.refPlaces)
reftransition_ids(page::Page) = map(pid, page.refTransitions)
refplace(page::Page, id::Symbol) = getfirst(x -> pid(x) === id, refplaces(page))
reftransition(page::Page, id::Symbol) = getfirst(x -> pid(x) === id, reftransitions(page))

#------------------------------------------------------------------
# PLACES, MARKING,
#------------------------------------------------------------------

function has_place(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    any(x -> pid(x) === id, places(petrinet))
end
function place(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    getfirst(x -> pid(x) === id, places(petrinet))
end
function marking(petrinet::N, placeid::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    marking(place(petrinet, placeid)) #TODO specialization?
end
place_ids(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} = map(pid, places(petrinet))

function initialMarking end

initialMarking(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} =
    initialMarking(petrinet, place_ids(petrinet))

function initialMarking(petrinet::N, placeid_vec::Vector{Symbol}) where {T<:PnmlType, N<:PetriNet{T}}
    LVector( (; [p=>marking(petrinet, p) for p in placeid_vec]...))
end

has_place(net::PnmlNet, id::Symbol, page=1) = has_place(net.pages[page], id)
place(net::PnmlNet, id::Symbol, page_idx=1) = place(net.pages[page_idx], id)
place_ids(net::PnmlNet, page_idx=1) = place_ids(net.pages[page_idx])

marking(net::PnmlNet, placeid::Symbol, page_idx=1) = marking(net.pages[page_idx], placeid)

initialMarking(net::PnmlNet, page_idx=1) = initialMarking(net.pages[page_idx])

function initialMarking(net::PnmlNet, placeid_vec::Vector{Symbol})
    LVector( (; [p=>marking(net, p) for p in placeid_vec]...))
end

has_place(page::Page, id::Symbol) = any(x -> pid(x) === id, places(page))
place(page::Page, id::Symbol) = getfirst(x -> pid(x) === id, places(page))
place_ids(page::Page) = map(pid, places(page))

marking(page::Page,  placeid::Symbol) = marking(place(page, placeid))

#TODO Use marking (initialiezd to initialMarking in constructor).
# Return all places' marking as LVector
initialMarking(page::Page) = initialMarking(page, place_ids(page))
function initialMarking(page::Page, placeid_vec::Vector{Symbol})
    LVector( (; [p=>marking(page, p) for p in placeid_vec]...))
end


#------------------------------------------------------------------
# TRANSITIONS, CONDITIONS
#------------------------------------------------------------------
"""
$(TYPEDSIGNATURES)

Return function to be used like: any(ispid(sym), iterater_with_pid)
"""
ispid(x) = Base.Fix2(===, x)

function has_transition(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    #any(x -> pid(x) === id, transitions(petrinet))
    any(Base.Fix2(===,id), transition_ids(petrinet))
end

function transition(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    getfirst(x -> pid(x) === id, transitions(petrinet))
end
transition_ids(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} =
    map(pid, transitions(petrinet))

has_transition(net::PnmlNet, id::Symbol, page_idx=1) = has_transition(net.pages[page_idx], id)
transition(net::PnmlNet, id::Symbol, page_idx=1) = transition(net.pages[page_idx], id)
transition_ids(net::PnmlNet, page_idx=1) = transition_ids(net.pages[page_idx])

has_transition(page::Page, id::Symbol) = any(x -> pid(x) === id, page.transitions)
transition(page::Page, id::Symbol) = getfirst(x -> pid(x) === id, transitions(page))
transition_ids(page::Page) = map(pid, page.transitions)

#----------------------------------------

conditions(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} =
    conditions(petrinet, transition_ids(petrinet))

function conditions(petrinet::N, idvec::Vector{Symbol}) where {T<:PnmlType, N<:PetriNet{T}}
    LVector( (; [t=>condition(petrinet, t) for t in idvec]...))
end

conditions(net::PnmlNet, page_idx=1) = conditions(net.pages[page_idx])

conditions(page::Page) = conditions(page, transition_ids(page))
conditions(page::Page, idvec::Vector{Symbol}) =
    LVector( (; [t=>condition(page, t) for t in idvec]...))

function condition(petrinet::N, trans_id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    condition(transition(petrinet, trans_id))
end

condition(net::PnmlNet, trans_id::Symbol, page_idx=1) = condition(net.pages[page_idx], trans_id)
condition(page::Page, trans_id::Symbol) = condition(transition(page, trans_id))

#-----------------------------------------------------------------
"""
$(TYPEDSIGNATURES)

Transition function of a Petri Net.
Each transition has an input vector and an output vector.
Each labelled vector is indexed by the place on the other end of the arc.
Values are inscriptions.
"""
function transition_function end

function transition_function(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}}
    transition_function(petrinet, transition_ids(petrinet))
end

function transition_function(petrinet::N, idvec::Vector{Symbol}) where {T<:PnmlType, N<:PetriNet{T}}
    LVector( (; [t=>in_out(petrinet,t) for t in idvec]...))
end

transition_function(net::PnmlNet, page_idx=1) = transition_function(net.pages[page_idx])
transition_function(page::Page, idvec::Vector{Symbol}) =
    LVector( (; [t=>in_out(page, t) for t in idvec]...))

"""
$(TYPEDSIGNATURES)

Return tuple of input, output labelled vectors with key of place ids and
value of arc inscription's value for use as a transition function.
#TODO When do these get called "pre" and "post"?
"""
function in_out end

function in_out(petrinet::N, transition_id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
        (ins(petrinet, transition_id), outs(petrinet, transition_id))
end

in_out(net::PnmlNet, transition_id::Symbol, page_idx=1) =
    in_out(net.pages[page_idx], transition_id)

in_out(page::Page, transition_id::Symbol) =
    (ins(page, transition_id), outs(page, transition_id))

"""
$(TYPEDSIGNATURES)
Return arcs of `p` that have `transition_id` as the target.
"""
ins(p, transition_id::Symbol) =
    LVector( (; [source(a)=>inscription(a) for a in tgt_arcs(p, transition_id)]...))

"""
$(TYPEDSIGNATURES)
Return arcs of `p` that have `transition_id` as the source.
"""
outs(p, transition_id::Symbol) =
    LVector( (; [target(a)=>inscription(a) for a in src_arcs(p, transition_id)]...))

#------------------------------------------------------------------
#
#------------------------------------------------------------------

