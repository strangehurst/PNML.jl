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

Pages are used for visual layout for humans.
They can be merged into one page without losing any Petri Net semantics.
Often we will only work with merged pages.
"""
abstract type PetriNet{T<:PnmlType} end




#----------------------------------------------------------------------------------

"""
Return the PnmlType subtype representing the flavor (or pntd) of this kind of Petri Net.

$(TYPEDSIGNATURES)
"""
type(petrinet::N) where {T <: PnmlType, N <: PetriNet{T}} = T
type(net::PnmlNet{T}, page=1) where {T <: PnmlType} = T
type(page::Page{T}) where {T <: PnmlType} = T




#------------------------------------------------------------------
# Methods that should be implemented by concrete subtypes.
#------------------------------------------------------------------

pid(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} = error("must implement id accessor")

"""
$(TYPEDSIGNATURES)

Return vector of places.
"""
function places end
places(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} = error("not implemented")
places(net::PnmlNet, page=1) = places(net.pages[page])
places(page::Page) = page.places

"""
$(TYPEDSIGNATURES)
Return vector of transitions.
"""
function transitions end
transitions(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} = error("not implemented")
transitions(net::PnmlNet, page=1) = transitions(net.pages[page])
transitions(page::Page) = page.transitions

"""
$(TYPEDSIGNATURES)

Return vector of arcs.
"""
function arcs end
arcs(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} = error("not implemented")
arcs(net::PnmlNet, page=1) = arcs(net.pages[page])
arcs(page::Page) = page.arcs

"""
$(TYPEDSIGNATURES)
Return vector of reference places.
"""
function refplaces end
refplaces(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} = error("not implemented")
refplaces(net::PnmlNet, page=1) = refplaces(net.pages[page])
refplaces(page::Page) = page.refplaces

"""
$(TYPEDSIGNATURES)

Return vector of reference transitions.
"""
function reftransitions end
reftransitions(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} = error("not implemented")
reftransitions(net::PnmlNet, page=1) = reftransitions(net.pages[page])
reftransitions(page::Page) = page.reftransitions

#------------------------------------------------------------------
# ARC, INSCRIPTION
#------------------------------------------------------------------

#TODO: wrap arc?
"""
$(TYPEDSIGNATURES)

Return symbol of source of `arc`.
"""
source(arc)::Symbol = arc.source

"""
$(TYPEDSIGNATURES)

Return symbol of target of `arc`.
"""
target(arc)::Symbol = arc.target

"""
$(TYPEDSIGNATURES)

Return `true` if any `arc` in `petrinet` has `id`.
"""
function has_arc end
function has_arc(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    any(x -> pid(x) === id, arcs(petrinet))
end
has_arc(net::PnmlNet, id::Symbol, page=1) = has_arc(net.pages[page], id)
has_arc(page::Page, id::Symbol) = any(x -> pid(x) === id, arcs(page))

"""
$(TYPEDSIGNATURES)
Return arc of `petrinet` with `id` if found, otherwise `nothing`.
"""
function arc end
function arc(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    arcs(petrinet)[findfirst(x -> pid(x) === id, arcs(petrinet))]
end
arc(net::PnmlNet, id::Symbol, page=1) = arc(net.pages[page], id)
arc(page::Page, id::Symbol) = page.arcs[findfirst(x -> pid(x) === id, page.arcs)]

"""
$(TYPEDSIGNATURES)

Return vector of `petrinet`'s arc ids.
"""
function arc_ids end
arc_ids(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} = map(pid, arcs(petrinet))
arc_ids(net::PnmlNet, page=1) = arc_ids(net.pages[page])
arc_ids(page::Page) = map(pid, page.arcs)

"""
$(TYPEDSIGNATURES)
Return vector of arcs that have a source or target of transition `id`.

See also [`src_arcs`](@ref), [`tgt_arcs`](@ref).
"""
function all_arcs end
function all_arcs(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    filter(a->source(a)===id || target(a)===id, arcs(petrinet))
end
all_arcs(net::PnmlNet, id::Symbol, page=1) = all_arcs(net.pages[page], id)
all_arcs(page::Page, id::Symbol) = filter(a->source(a)===id, arcs(page))

"""
$(TYPEDSIGNATURES)

Return vector of arcs that have a source of transition `id`.

See also [`all_arcs`](@ref), [`tgt_arcs`](@ref).
"""
function src_arcs end
function src_arcs(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    filter(a->source(a)===id, arcs(petrinet))
end
src_arcs(net::PnmlNet, id::Symbol, page=1) = src_arcs(net.pages[page], id)
src_arcs(page::Page, id::Symbol) = filter(a->source(a)===id, arcs(page))

"""
$(TYPEDSIGNATURES)

Return vector of arcs that have a target of transition `id`.

See also [`all_arcs`](@ref), [`src_arcs`](@ref).
"""
function tgt_arcs end
function tgt_arcs(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    filter(a->target(a)===id, arcs(petrinet))
end
tgt_arcs(net::PnmlNet, id::Symbol, page=1) = tgt_arcs(net.pages[page], id)
tgt_arcs(page::Page, id::Symbol) = filter(a->source(a)===id, arcs(page))

"""
$(TYPEDSIGNATURES)
Return incription value of `arc`.
"""
function inscription end

# This is evaluating the incscription attached to an arc.
# Original implementation is for PTNet.
# HLNets do usual label semantics  here.
# Map from net.type to inscription
function inscription(arc)
    if !isnothing(arc.inscription)
        # Evaluate inscription
        #TODO Is this where a functor is called to get a value?
        arc.inscription.value
    else
        # Default inscription value.
        one(Int) #TODO: match value type.
    end
end

function inscription(petrinet::N, arc_id::Symbol) where {T <: PnmlType, N <: PetriNet{T}}
    inscription(arc(petrinet, arc_id))
end
inscription(net::PnmlNet, id::Symbol, page=1) = inscription(net.pages[page], id)
inscription(page::Page, id::Symbol) = inscription(arc(page, arc_id))

#------------------------------------------------------------------
# REFERENCES
#------------------------------------------------------------------

"""
$(TYPEDSIGNATURES)
"""
function has_refP end
function has_refP(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    any(x -> pid(x) === id, refplaces(petrinet))
end
has_refP(net::PnmlNet, id::Symbol, page=1) = has_refP(net.pages[page], id)
has_refP(page::Page, id::Symbol) = any(x -> pid(x) === id, refplaces(page))

"""
$(TYPEDSIGNATURES)
"""
function has_refT end
function has_refT(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    any(x -> pid(x) === id, reftransitions(petrinet))
end
has_refT(net::PnmlNet, id::Symbol, page=1) = has_refP(net.pages[page], id)
has_refT(page::Page, id::Symbol) = any(x -> pid(x) === id, reftransitions(page))


"""
$(TYPEDSIGNATURES)
"""
function refplace_ids end
refplace_ids(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} =
    map(pid, refplaces(petrinet))
refplace_ids(net::PnmlNet, page=1) = refplace_ids(net.pages[page])
refplace_ids(page::Page) = map(pid, page.refPlaces)

"""
$(TYPEDSIGNATURES)
"""
function reftransition_ids end
reftransition_ids(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} =
    map(pid, reftransitions(petrinet))
reftransition_ids(net::PnmlNet, page=1) = reftransition_ids(net.pages[page])
reftransition_ids(page::Page) = map(pid, page.refTransitions)

"""
Return reference place matchind `id`.
$(TYPEDSIGNATURES)
"""
function refplace end
function refplace(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    refplaces(petrinet)[findfirst(x -> pid(x) === id, refplaces(petrinet))]
end
refplace(net::PnmlNet, id::Symbol, page=1) = refplace(net.pages[page], id)
refplace(page::Page, id::Symbol) =
    refplaces(page)[findfirst(x -> pid(x) === id, refplaces(page))]

"""
Return reference transition matching `id`.
$(TYPEDSIGNATURES)
"""
function reftransition end
function reftransition(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    reftransitions(petrinet)[findfirst(x -> pid(x) === id, reftransitions(petrinet))]
end
reftransition(net::PnmlNet, id::Symbol, page=1) = reftransition(net.pages[page], id)
reftransition(page::Page, id::Symbol) =
    reftransitions(page)[findfirst(x -> pid(x) === id, reftransitions(page))]

"""
$(TYPEDSIGNATURES)

Remove reference nodes from arcs.
Design intent expects [`flatten_pages!`](@ref) to have
been applied so that everything is on one page.

# Axioms
  1) All ids in a network are unique in that they only have one instance in the XML.
  2) A chain of reference Places or Transitions always ends at a Place or Transition.
  3) All ids are valid.
"""
function deref! end

deref!(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} = _deref!(petrinet)
deref!(net::PnmlNet, page=1) = deref!(net.pages[page])
deref!(page::Page) = _deref!(page)

function _deref!(p)
    for a in arcs(p)
        while a.source ∈ refplace_ids(p)
            a.source = deref_place(p, a.source)
        end
        while a.target ∈ refplace_ids(p)
            a.target = deref_place(p, a.target)
        end
        while a.source ∈ reftransition_ids(p)
            a.source = deref_transition(p, a.source)
        end
        while a.target ∈ reftransition_ids(p)
            a.target = deref_transition(p, a.target)
        end
    end
end

"""
$(TYPEDSIGNATURES)

Return id of referenced place.
"""
function deref_place end
deref_place(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}} =
    refplace(petrinet, id).ref
deref_place(net::PnmlNet, id::Symbol, page=1) = deref_place(net.pages[page], id)
deref_place(page::Page, id::Symbol) =
    page.places[findfirst(p->pid(p)===id, page.places)].ref

"""
$(TYPEDSIGNATURES)

Return id of referenced transition.
"""
function deref_transition end
deref_transition(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}} =
    reftransition(petrinet, id).ref
deref_transition(net::PnmlNet, id::Symbol, page=1) = deref_transition(net.pages[page], id)
deref_transition(page::Page, id::Symbol) = reftransition(page, id).ref


#------------------------------------------------------------------
# PLACES, MARKING,
#------------------------------------------------------------------

"""
$(TYPEDSIGNATURES)

Is there any place with `id` in `petrinet`?
"""
function has_place end
function has_place(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    any(x -> pid(x) === id, places(petrinet))
end

has_place(net::PnmlNet, id::Symbol, page=1) = has_place(net.pages[page], id)
has_place(page::Page, id::Symbol) = any(x -> pid(x) === id, places(page))

"""
$(TYPEDSIGNATURES)

Return the place with `id` in `petrinet`.
"""
function place end
function place(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    places(petrinet)[findfirst(x -> pid(x) === id, places(petrinet))]
end
place(net::PnmlNet, id::Symbol, page=1) = place(net.pages[page], id)
place(page::Page, id::Symbol) = page.places[findfirst(x -> pid(x) === id, places(page))]

"""
$(TYPEDSIGNATURES)

Return vector of place ids in `petrinet`.
"""
function place_ids end
place_ids(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} = map(pid, places(petrinet))
place_ids(net::PnmlNet, page=1) = place_ids(net.pages[page])
place_ids(page::Page) = map(pid, places(page))

"""
$(TYPEDSIGNATURES)

Return marking value of a place `p`.
"""
function marking end

function marking(place)
    #TODO PNTD specific marking semantics. Including structures
    if !isnothing(place.marking)
        # Evaluate marking.
        place.marking.value
    else
        0 #TODO return default marking
    end
end

function marking(petrinet::N, placeid::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    #TODO force specialization? Use trait? #MOVE to parser
    marking(place(petrinet, placeid))
end
marking(net::PnmlNet, placeid::Symbol, page=1) = marking(net.pages[page], placeid)
marking(page::Page,  placeid::Symbol) = marking(place(page, placeid))



"""
$(TYPEDSIGNATURES)

Return a labelled vector with key of place id and value of marking.
"""
function initialMarking end
initialMarking(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} =
    initialMarking(petrinet, place_ids(petrinet))
initialMarking(net::PnmlNet, page=1) = initialMarking(net.pages[page])
initialMarking(page::Page) = initialMarking(page, place_ids(page))

function initialMarking(petrinet::N, placeid_vec::Vector{Symbol}) where {T<:PnmlType, N<:PetriNet{T}}
    LVector( (; [p=>marking(petrinet, p) for p in placeid_vec]...))
end
function initialMarking(page::Page, placeid_vec::Vector{Symbol})
    LVector( (; [p=>marking(page, p) for p in placeid_vec]...))
end


#------------------------------------------------------------------
# TRANSITIONS, CONDITIONS
#------------------------------------------------------------------

"""
$(TYPEDSIGNATURES)

Is there a transition with `id` in net `petrinet`?
"""
function has_transition end
function has_transition(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    any(x -> pid(x) === id, transitions(petrinet))
end
has_transition(net::PnmlNet, id::Symbol, page=1) = has_transition(net.pages[page], id)
has_transition(page::Page, id::Symbol) = any(x -> pid(x) === id, page.transitions)

"""
$(TYPEDSIGNATURES)
"""
function transition end
function transition(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    transitions(petrinet)[findfirst(x -> pid(x) === id, transitions(petrinet))]
end
transition(net::PnmlNet, id::Symbol, page=1) = transition(net.pages[page], id)
transition(page::Page, id::Symbol) =
    transitions(page)[findfirst(x -> pid(x) === id, transitions(page))]

"""
$(TYPEDSIGNATURES)
"""
function transition_ids end
transition_ids(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} =
    map(pid, transitions(petrinet))
transition_ids(net::PnmlNet, page=1) = transition_ids(net.pages[page])
transition_ids(page::Page) = map(pid, page.transitions)

#----------------------------------------

"""
$(TYPEDSIGNATURES)

Return a labelled vector of condition values for net `s`. Key is transition id.
"""
function conditions end

conditions(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} =
    conditions(petrinet, transition_ids(petrinet))

function conditions(petrinet::N, idvec::Vector{Symbol}) where {T<:PnmlType, N<:PetriNet{T}}
    LVector( (; [t=>condition(petrinet, t) for t in idvec]...))
end

conditions(net::PnmlNet, page=1) = conditions(net.pages[page])
conditions(page::Page) = conditions(page, transition_ids(page))
conditions(page::Page, idvec::Vector{Symbol}) =
    LVector( (; [t=>condition(page, t) for t in idvec]...))

"""
$(TYPEDSIGNATURES)

Return condition value of `transition`.
"""
function condition end

# TODO Specialize on PNTD.
function condition(transition)
    if isnothing(transition.condition) || isnothing(transition.condition.text)
        zero(Int) # TODO default condition
    else
        #TODO evaluate condition
        #TODO implement full structure handling
        rate = number_value(transition.condition.text)
        isnothing(rate) ? zero(Int) : rate
    end
end

function condition(petrinet::N, trans_id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    condition(transition(petrinet, trans_id))
end

condition(net::PnmlNet, trans_id::Symbol, page=1) = condition(net.pages[page], trans_id)
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

transition_function(net::PnmlNet, page=1) = transition_function(net.pages[page])
transition_function(page::Page, idvec::Vector{Symbol}) =
    LVector( (; [t=>in_out(page, t) for t in idvec]...))


"""
$(TYPEDSIGNATURES)

Return tuple of input, output labelled vectors with key of place ids and
value of arc inscription's value for use as a transition function.
"""
function in_out end
function in_out(petrinet::N, transition_id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
        (ins(petrinet, transition_id), outs(petrinet, transition_id))
end

in_out(net::PnmlNet, transition_id::Symbol, page=1) = in_out(net.pages[page], transition_id)

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
