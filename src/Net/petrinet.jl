"""
Provides 2nd-level parsing of the intermediate representation
of a  **single network** in a PNML.Document.

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
$(METHODLIST)
"""
type(petrinet::N) where {T <: PnmlType, N <: PetriNet{T}} = T

#------------------------------------------------------------------
# Methods that should be implemented by concrete subtypes.
#------------------------------------------------------------------

pid(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} = error("must implement id accessor")

"""
Return vector of places. 

$(TYPEDSIGNATURES)
$(METHODLIST)
"""
places(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} = error("not implemented")

"""
Return vector of transitions. 

$(TYPEDSIGNATURES)
$(METHODLIST)
"""
transitions(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} = error("not implemented")

"""
Return vector of arcs. 

$(TYPEDSIGNATURES)
$(METHODLIST)
"""
arcs(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} = error("not implemented")

"""
Return vector of reference places. 

$(TYPEDSIGNATURES)
$(METHODLIST)
"""
refplaces(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} = error("not implemented")

"""
Return vector of reference transitions. 

$(TYPEDSIGNATURES)
$(METHODLIST)
"""
reftransitions(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} = error("not implemented")

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
function has_arc(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    any(x -> pid(x) === id, arcs(petrinet))
end

"""
Return arc of `petrinet` with `id` if found, otherwise `nothing`.

---
$(TYPEDSIGNATURES)
"""
function arc(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    arcs(petrinet)[findfirst(x -> pid(x) === id, arcs(petrinet))]
end

"""
$(TYPEDSIGNATURES)
Return vector of `petrinet`'s arc ids.
"""
arc_ids(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} = map(pid, arcs(petrinet)) 

"""
$(TYPEDSIGNATURES)

Return vector of arcs that have a source or target of transition `id`.
See also [`src_arcs`](@ref), [`tgt_arcs`](@ref).
"""
function all_arcs(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    filter(a->source(a)===id || target(a)===id, arcs(petrinet))
end

"""
$(TYPEDSIGNATURES)

Return vector of arcs that have a source of transition `id`.
See also [`all_arcs`](@ref), [`tgt_arcs`](@ref).
"""
function src_arcs(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    filter(a->source(a)===id, arcs(petrinet))
end

"""
$(TYPEDSIGNATURES)

Return vector of arcs that have a target of transition `id`.
See also [`all_arcs`](@ref), [`src_arcs`](@ref).
"""
function tgt_arcs(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    filter(a->target(a)===id, arcs(petrinet))
end


"""
Return incription value of `arc`.

---
$(TYPEDSIGNATURES)

$(METHODLIST)
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
        # Default inscription
        1 # Omitted PTNet inscriptions default value. TODO: match value type.
    end        
end

function inscription(petrinet::N, arc_id::Symbol) where {T <: PnmlType, N <: PetriNet{T}}
    inscription(arc(petrinet, arc_id))
end

#------------------------------------------------------------------
# REFERENCES
#------------------------------------------------------------------

"""
$(TYPEDSIGNATURES)
"""
function has_refP(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    any(x -> pid(x) === id, refplaces(petrinet))
end

"""
$(TYPEDSIGNATURES)
"""
function has_refT(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    any(x -> pid(x) === id, reftransitions(petrinet))
end

"""
$(TYPEDSIGNATURES)
"""
refplace_ids(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} =
    map(pid, refplaces(petrinet)) 

"""
$(TYPEDSIGNATURES)
"""
reftransition_ids(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} =
    map(pid, reftransitions(petrinet)) 

"""
$(TYPEDSIGNATURES)
"""
function refplace(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    refplaces(petrinet)[findfirst(x -> pid(x) === id, refplaces(petrinet))]
end

"""
$(TYPEDSIGNATURES)
"""
function reftransition(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    reftransitions(petrinet)[findfirst(x -> pid(x) === id, reftransitions(petrinet))]
end

"""
Remove reference nodes from arcs.
Design intent expects [`flatten_pages!`](@ref) to have
been applied so that everything is on one page.
---
$(TYPEDSIGNATURES)

$(METHODLIST)

# Examples
## Axioms
  1) All ids in a PNML.Document are unique in that they only have one instance in the XML.
  2) A chain of reference Places or Transitions always ends at a Place or Transition.
  3) All ids are valid.
"""
function deref! end

function deref!(petrinet::N) where {T <: PnmlType, N <: PetriNet{T}} 
    for a in arcs(petrinet)
        while a.source ∈ refplace_ids(petrinet)
            @debug a.source, deref_place(petrinet, a.source)
            a.source = deref_place(petrinet, a.source)
        end
        while a.target ∈ refplace_ids(petrinet)
            @debug a.target, deref_place(petrinet, a.target)
            a.target = deref_place(petrinet, a.target)
        end
        while a.source ∈ reftransition_ids(petrinet)
            @debug a.source, deref_transition(petrinet, a.source)
            a.source = deref_transition(petrinet, a.source)
        end
        while a.target ∈ reftransition_ids(petrinet)
            @debug a.target, deref_transition(petrinet, a.target)
            a.target = deref_transition(petrinet, a.target)
        end        
    end
end



"""
$(TYPEDSIGNATURES)

Return id of referenced place.
"""
deref_place(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}} =
    refplace(petrinet, id).ref

"""
$(TYPEDSIGNATURES)

Return id of referenced transition.
"""
deref_transition(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}} =
    reftransition(petrinet, id).ref


#------------------------------------------------------------------
# PLACES, MARKING, 
#------------------------------------------------------------------

"""
$(TYPEDSIGNATURES)

Is there any place with `id` in `petrinet`?
"""
function has_place(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    any(x -> pid(x) === id, places(petrinet))
end

"""
$(TYPEDSIGNATURES)

Return the place with `id` in `petrinet`.
"""
function place(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    places(petrinet)[findfirst(x -> pid(x) === id, places(petrinet))]
end

"""
$(TYPEDSIGNATURES)

Return vector of place ids in `petrinet`.
"""
place_ids(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} = map(pid, places(petrinet)) 


"""
Return marking value of a place `p`.

---
$(TYPEDSIGNATURES)

$(METHODLIST)

# Examples

```jldoctest
julia> using PNML

julia> p = PNML.PTMarking(PNML.PnmlDict(:value=>nothing));

julia> p.value
0

julia> p = PNML.PTMarking(PNML.PnmlDict(:value=>12.34));

julia> p.value
12.34
```
"""
function marking end

function marking(place)
    #TODO PNTD specific marking semantics. Including structures
    if !isnothing(place.marking)
        # Evaluate marking.
        place.marking.value
    else
        0 #TODO returm default marking
    end
end

function marking(petrinet::N, placeid::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    #TODO force specialization? Use trait?
    marking(place(petrinet, placeid))
end



"""
$(TYPEDSIGNATURES)

Return a labelled vector with key of place id and value of marking.
"""
function initialMarking end
initialMarking(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} =
    initialMarking(petrinet, place_ids(petrinet))

function initialMarking(petrinet::N, placeid_vec::Vector{Symbol}) where {T<:PnmlType, N<:PetriNet{T}}
    LVector( (; [p=>marking(petrinet,p) for p in placeid_vec]...))
end


#------------------------------------------------------------------
# TRANSITIONS, CONDITIONS
#------------------------------------------------------------------

"""
$(TYPEDSIGNATURES)

Is there a transition with `id` in net `petrinet`?
"""
function has_transition(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    any(x -> pid(x) === id, transitions(petrinet))
end

"""
$(TYPEDSIGNATURES)
"""
function transition(petrinet::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    transitions(petrinet)[findfirst(x -> pid(x) === id, transitions(petrinet))]
end

"""
$(TYPEDSIGNATURES)
"""
transition_ids(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} =
    map(pid, transitions(petrinet)) 

#----------------------------------------

"""
Return a labelled vector of condition values for net `s`. Key is transition id.

---
$(TYPEDSIGNATURES)

$(METHODLIST)
"""
function conditions end
conditions(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}} =
    conditions(petrinet, transition_ids(petrinet))

function conditions(petrinet::N, idvec::Vector{Symbol}) where {T<:PnmlType, N<:PetriNet{T}}
    LVector( (; [t=>condition(petrinet,t) for t in idvec]...))
end

"""
Return condition value of `transition`.

---
$(TYPEDSIGNATURES)

$(METHODLIST)
"""
function condition end

# TODO Specialize on PNTD.
function condition(transition)
    if isnothing(transition.condition) || isnothing(transition.condition.text)
        0 # TODO default condition
    else
        #TODO evaluate condition
        #TODO implement full structure handling
        rate = number_value(transition.condition.text)
        isnothing(rate) ? 0 : rate
    end
end

function condition(petrinet::N, transition_id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    condition(transition(petrinet, transition_id))
end

#-----------------------------------------------------------------
"""
$(TYPEDSIGNATURES)

Transition function of a Petri Net.
Each transition has an input vector and an output vector.
Each labelled vector is indexed by the place on the other end of the arc.
Values are inscriptions.

---
$(TYPEDSIGNATURES)
$(METHODLIST)
"""
function transition_function end

function transition_function(petrinet::N) where {T<:PnmlType, N<:PetriNet{T}}
    transition_function(petrinet, transition_ids(petrinet))
end

function transition_function(petrinet::N, idvec::Vector{Symbol}) where {T<:PnmlType, N<:PetriNet{T}}
    LVector( (; [t=>in_out(petrinet,t) for t in idvec]...))
end

"""
$(TYPEDSIGNATURES)

Return tuple of input, output labelled vectors with key of place ids and
value of arc inscription's value. 
"""
function in_out(petrinet::N, transition_id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    # Input arcs have this transition as the target.
    ins = (; [source(a)=>inscription(a) for a in tgt_arcs(petrinet, transition_id)]...)
    # Output arcs have this transition as the source.
    out = (; [target(a)=>inscription(a) for a in src_arcs(petrinet, transition_id)]...)
    (LVector(ins), LVector(out))
end    

#------------------------------------------------------------------
# 
#------------------------------------------------------------------
