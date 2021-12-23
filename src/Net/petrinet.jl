"""
$(TYPEDEF)

Abstract type providing 2nd-level parsing of the intermediate representation
of a  **single network** in a PNML.Document.

# Extended

The type parameter of a nets should map directly and simply
to subtypes of [`PnmlType`](@ref).

Additional constranints can be imposed. We want to run under the motto:
"syntax is not semantics, quack".

Since a PNML.Document can contain multiple networks it is possible that a higher-level
will create multiple PNML.PetriNet instances, each a different subtype.

Pages are used for visual layout for humans.
They can be merged into one page without losing any Petri Net semantics.
Often we will only work with merged pages.
"""
abstract type PetriNet{T<:PnmlType} end




#----------------------------------------------------------------------------------

"""
$(TYPEDSIGNATURES)

Return the PnmlType subtype representing the flavor (or pntd) of this kind of Petri Net.
"""
type(s::N) where {T <: PnmlType, N <: PetriNet{T}} = T

#------------------------------------------------------------------
# Methods that should be implemented by concrete subtypes.
#------------------------------------------------------------------

pid(s::N) where {T<:PnmlType, N<:PetriNet{T}} = error("must implement id accessor")

"""
$(TYPEDSIGNATURES)
"""
places(s::N) where {T<:PnmlType, N<:PetriNet{T}} = error("not implemented")

"""
$(TYPEDSIGNATURES)
"""
transitions(s::N) where {T<:PnmlType, N<:PetriNet{T}} = error("not implemented")

"""
$(TYPEDSIGNATURES)
"""
arcs(s::N) where {T<:PnmlType, N<:PetriNet{T}} = error("not implemented")

"""
$(TYPEDSIGNATURES)
"""
refplaces(s::N) where {T<:PnmlType, N<:PetriNet{T}} = error("not implemented")

"""
$(TYPEDSIGNATURES)

Return vector of 
"""
reftransitions(s::N) where {T<:PnmlType, N<:PetriNet{T}} = error("not implemented")

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
"""
function has_arc(s::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    any(x -> pid(x) === id, arcs(s))
end

"""
$(TYPEDSIGNATURES)
"""
function arc(s::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    arcs(s)[findfirst(x -> pid(x) === id, arcs(s))]
end

"""
$(TYPEDSIGNATURES)
"""
arc_ids(s::N) where {T<:PnmlType, N<:PetriNet{T}} = map(pid, arcs(s)) 

"""
$(TYPEDSIGNATURES)

Return vector of arcs that have a source or target of transition `id`.
"""
function all_arcs(s::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    filter(a->source(a)===id || target(a)===id, arcs(s))
end

"""
$(TYPEDSIGNATURES)

Return vector of arcs that have a source of transition `id`.
"""
function src_arcs(s::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    filter(a->source(a)===id, arcs(s))
end

"""
$(TYPEDSIGNATURES)

Return vector of arcs that have a target of transition `id`.
"""
function tgt_arcs(s::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    filter(a->target(a)===id, arcs(s))
end


"""
$(TYPEDSIGNATURES)

Return incription value of `arc`.
"""
function inscription end

function inscription(arc)::Number
    if !isnothing(arc.inscription)
        arc.inscription.value
    else
        1
    end        
end

function inscription(s::N, a::Symbol) where {T <: PnmlType, N <: PetriNet{T}}
    inscription(arc(s,a))
end

#------------------------------------------------------------------
# REFERENCES
#------------------------------------------------------------------

"""
$(TYPEDSIGNATURES)
"""
function has_refP(s::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    any(x -> pid(x) === id, refplaces(s))
end

"""
$(TYPEDSIGNATURES)
"""
function has_refT(s::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    any(x -> pid(x) === id, reftransitions(s))
end

"""
$(TYPEDSIGNATURES)
"""
refplace_ids(s::N) where {T<:PnmlType, N<:PetriNet{T}} = map(pid, refplaces(s)) 

"""
$(TYPEDSIGNATURES)
"""
reftransition_ids(s::N) where {T<:PnmlType, N<:PetriNet{T}} = map(pid, reftransitions(s)) 

"""
$(TYPEDSIGNATURES)
"""
function refplace(s::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    refplaces(s)[findfirst(x -> pid(x) === id, refplaces(s))]
end

"""
$(TYPEDSIGNATURES)
"""
function reftransition(s::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    reftransitions(s)[findfirst(x -> pid(x) === id, reftransitions(s))]
end

"""
$(TYPEDSIGNATURES)

Remove reference nodes from arcs.
Design intent expects [`flatten_pages!`](@ref) to have
been applied so that everything is on one page.

# Examples
## Axioms
  1) All ids in a PNML.Document are unique in that they only have one instance in the XML.
  2) A chain of reference Places or Transitions always ends at a Place or Transition.
  3) All ids are valid.
"""
function deref! end

function deref!(s::N) where {T <: PnmlType, N <: PetriNet{T}} 
    for a in arcs(s)
        while a.source ∈ refplace_ids(s)
            @debug a.source, deref_place(s, a.source)
            a.source = deref_place(s, a.source)
        end
        while a.target ∈ refplace_ids(s)
            @debug a.target, deref_place(s, a.target)
            a.target = deref_place(s, a.target)
        end
        while a.source ∈ reftransition_ids(s)
            @debug a.source, deref_transition(s, a.source)
            a.source = deref_transition(s, a.source)
        end
        while a.target ∈ reftransition_ids(s)
            @debug a.target, deref_transition(s, a.target)
            a.target = deref_transition(s, a.target)
        end        
    end
end



"""
$(TYPEDSIGNATURES)

Return id of referenced place.
"""
deref_place(s::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}} = refplace(s, id).ref

"""
$(TYPEDSIGNATURES)

Return id of referenced transition.
"""
deref_transition(s::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}} = reftransition(s, id).ref


#------------------------------------------------------------------
# PLACES, MARKING, 
#------------------------------------------------------------------

"""
$(TYPEDSIGNATURES)

Is there any place with `id` in net `s`?
"""
function has_place(s::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    any(x -> pid(x) === id, places(s))
end

"""
$(TYPEDSIGNATURES)

Return the place with `id` in net `s`.
"""
function place(s::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    places(s)[findfirst(x -> pid(x) === id, places(s))]
end

"""
$(TYPEDSIGNATURES)

Return vector of place ids in `s`.
"""
place_ids(s::N) where {T<:PnmlType, N<:PetriNet{T}} = map(pid, places(s)) 


"""
$(TYPEDSIGNATURES)

Return marking value of a place `p`.

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

function marking(place)::Number
    #TODO PNTD specific marking semantics. Including structures
    if !isnothing(place.marking)
        place.marking.value
    else
        0
    end
end

function marking(s::N, p::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    #TODO force specialization? Use trait?
    marking(place(s,p))
end



"""
$(TYPEDSIGNATURES)

Return a labelled vector with key of place ids and value of marking.
"""
function initialMarking end
initialMarking(s::N) where {T<:PnmlType, N<:PetriNet{T}} = initialMarking(s, place_ids(s))

function initialMarking(s::N, v::Vector{Symbol}) where {T<:PnmlType, N<:PetriNet{T}}
    LVector( (; [p=>marking(s,p) for p in v]...))
end


#------------------------------------------------------------------
# TRANSITIONS, CONDITIONS
#------------------------------------------------------------------

"""
$(TYPEDSIGNATURES)

Is there a transition with `id` in net `s`?
"""
function has_transition(s::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    any(x -> pid(x) === id, transitions(s))
end

"""
$(TYPEDSIGNATURES)
"""
function transition(s::N, id::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    transitions(s)[findfirst(x -> pid(x) === id, transitions(s))]
end

"""
$(TYPEDSIGNATURES)
"""
transition_ids(s::N) where {T<:PnmlType, N<:PetriNet{T}} = map(pid, transitions(s)) 

#----------------------------------------

"""
$(TYPEDSIGNATURES)

Return a labelled vector of condition values for net `s`. Key is transition id.
"""
function conditions end
conditions(s::N) where {T<:PnmlType, N<:PetriNet{T}} = conditions(s, transition_ids(s))

function conditions(s::N, v::Vector{Symbol}) where {T<:PnmlType, N<:PetriNet{T}}
    LVector( (; [t=>condition(s,t) for t in v]...))
end

"""
Return condition value of `transition`.
"""
function condition end

# TODO Specialize on PNTD.
function condition(transition)::Number
    if isnothing(transition.condition) || isnothing(transition.condition.text)
        0
    else
        #TODO implement full structure handling
        rate = number_value(transition.condition.text)
        isnothing(rate) ? 0 : rate
    end
end

function condition(s::N, t::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    condition(transition(s,t))
end

#-----------------------------------------------------------------
"""
$(TYPEDSIGNATURES)

Transition function of a Petri Net.
Each transition has an input vector and an output vector.
Each labelled vector is indexed by the place on the other end of the arc.
Values are inscriptions.
"""
function transition_function end

function transition_function(s::N) where {T<:PnmlType, N<:PetriNet{T}}
    transition_function(s, transition_ids(s))
end

function transition_function(s::N, v::Vector{Symbol}) where {T<:PnmlType, N<:PetriNet{T}}
    LVector( (; [t=>in_out(s,t) for t in v]...))
end

"""
$(TYPEDSIGNATURES)

Return tuple of input, output labelled vectors with key of place ids and
value of arc inscription's value. 
"""
function in_out(s::N, t::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    # Input arcs have this transition as the target.
    ins = (; [source(a)=>inscription(a) for a in tgt_arcs(s, t)]...)
    # Output arcs have this transition as the source.
    out = (; [target(a)=>inscription(a) for a in src_arcs(s, t)]...)
    (LVector(ins), LVector(out))
end    

#------------------------------------------------------------------
# 
#------------------------------------------------------------------
