"""
$(TYPEDEF)

Abstract type providing 2nd-level parsing of the intermediate representation
of a single network in a PNML.Document.

# Extended

Subtypes should map directly and simply to [`PnmlType`](@ref).

Since a PNML.Document can contain multiple networks it is possible that a higher-level
will create multiple PNML.PetriNet instances, each a different subtype.

Pages are used for visual layout for humans.
They can be merged into one page without loosing any Petri Net semantics.
Often we will only work with merged pages.

# Interface
#TODO define type for network IR: Wrap a single tag net's [`PnmlDict`](@ref)?
We start a description of the net IR here. 

XML <net> tags are pnml nodes.
These nodes are parsed into PnmlDict with keys
| key          | value description                             |
|:-------------|:----------------------------------------------|
[ tag          | XML tag name is standard in the IR            |
| id           | unique ID                                     |
| name         | text name, optional                           |
| tools        | set of tool specific - possibly empty         |
| labels       | set of generic "pnml labels" - possible empty |
| type         | PnmlType defines schema the XML should meet   |
| declarations | defines high-level semantics of a net         |
| pages        | set of pages - not empty                      |

See [`pnml_common_defaults`](@ref), [`pnml_node_defaults`](@ref)
and  [`parse_net`](@ref) for more detail.

XML <page> tags are also parsed into PnmlDict
| key          | value description                             |
|:-------------|:----------------------------------------------|
[ tag          | XML tag name is standard in the IR            |
| id           | unique ID                                     |
| name         | text name, optional                           |
| tools        | set of tool specific - possibly empty         |
| labels       | set of generic "pnml labels" - possible empty |
| places       |                                               |
| trans        |                                               |
| arcs         |                                               |
| refP         | reference to place on different page          |
| refT         | reference to transition on different page     |
| declarations | only net & page tags have declarations        |

See [`parse_page`](@ref), [`parse_net`](@ref)
"""
abstract type PetriNet end

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

=#

"""
$(TYPEDEF)

$(TYPEDFIELDS)

SimpleNet wraps the `place`, `transition` & `arc` collections of a single page of one net.

Omits the page level of the pnml-defined hierarchy by collapsing down to one page.
A multi-page net can be collpsed by removing referenceTransitions & referencePlaces,
and merging pages into the first page. Only selected fields are merged.
"""
struct SimpleNet{P,T,A,RT,RP,L,TI} <: PetriNet
    "Same as the XML attribute of the same name."
    id::Symbol
    
    place::P
    transition::T
    arc::A
    refT::RT
    refP::RP
    label::L
    tools::TI
    #declatations:D #TODO
end


SimpleNet(str::AbstractString) = SimpleNet(Document(str))
SimpleNet(doc::Document)       = SimpleNet(first_net(doc))

# Single network is the heart of PetriNet.
function SimpleNet(net::PnmlDict)
    netcopy = deepcopy(net)
    collapse_pages!(netcopy)
    p1 = netcopy[:pages][1]
    SimpleNet(netcopy[:id], 
              haskey(p1, :places) ? p1[:places] : nothing,
              haskey(p1, :trans) ?  p1[:trans] : nothing,
              haskey(p1, :arcs) ?   p1[:arcs] : nothing,
              haskey(p1, :refT) ?   p1[:refT] : nothing,
              haskey(p1, :refP) ?   p1[:refP] : nothing,
              haskey(p1, :labels) ? p1[:labels] : nothing, # merge page & net labels
              haskey(p1, :tools) ?  p1[:tools] : nothing) # merge page & net tools
end

"""
$(TYPEDSIGNATURES)
Return id field of `s`.
"""
id(s::T) where {T <: PetriNet} = s.id

function Base.show(io::IO, s::SimpleNet{P,T,A}) where {P,T,A}
    println(io, "PNML.SimpleNet{$P,$T,$A}(")
    println(io, "id=", id(s), ", ",
            length(places(s)), " places, ",
            length(transitions(s)), " transitions, ",
            length(arcs(s)), " arcs")
    println(io, id(s), " places")
    pprintln(io, places(s))
    println(io, id(s), " transitions")
    pprintln(io, transitions(s))
    println(io, id(s), " arcs")
    pprintln(io, arcs(s))
    print(io, ")")
end


"""
$(TYPEDEF)

$(TYPEDFIELDS)
"""
struct HLPetriNet{T} <: PetriNet
    id::Symbol
    net::PnmlDict
end
HLPetriNet(str::AbstractString) = HLPetriNet(Document(str))
HLPetriNet(doc::Document)       = HLPetriNet(first_net(doc))

# Single network is the heart of PetriNet.
"""
$(TYPEDSIGNATURES)
"""
function HLPetriNet(net::PnmlDict)
    HLPetriNet{typeof(net[:type])}(net[:id], collapse_pages!(net))
end

"""
$(TYPEDSIGNATURES)

Merge page content into the 1st page of each pnml net.
Note that refrence nodes are still present. They can be removed later
with [`deref!`](@ref).
"""
function collapse_pages! end

function collapse_pages!(doc::PNML.Document)
    foreach(collapse_pages!, nets(doc))
end

function collapse_pages!(net::PnmlDict)
    @assert net[:tag] === :net

    # Some of the keys are optional. They may be removed by a compress before collapse.
    for key in [:places, :trans, :arcs, :tools, :labels, :refT, :refP, :declarations]
        tmp = PnmlDict[]
        foreach(net[:pages]) do page
            if haskey(page, key) && !isnothing(page[key])
                push!.(Ref(tmp), page[key]) #TODO test this syntax
                empty!(page[key])
            end
        end
        if !isempty(tmp)
            net[:pages][1][key] = tmp
        end
    end
    net
end

"""
$(TYPEDSIGNATURES)
"""
places(s::SimpleNet) = s.place
"""
$(TYPEDSIGNATURES)
"""
transitions(s::SimpleNet) = s.transition
"""
$(TYPEDSIGNATURES)
"""
arcs(s::SimpleNet) = s.arc
"""
$(TYPEDSIGNATURES)
"""
refplaces(s::SimpleNet) = s.refP
"""
$(TYPEDSIGNATURES)
"""
reftransitions(s::SimpleNet) = s.refT

"""
$(TYPEDSIGNATURES)
Is there any place with `id` in net `s`?
"""
has_place(s::SimpleNet, id::Symbol)      = any(x -> x[:id] === id, places(s))
"""
$(TYPEDSIGNATURES)
"""
has_transition(s::SimpleNet, id::Symbol) = any(x -> x[:id] === id, transitions(s))
"""
$(TYPEDSIGNATURES)
"""
has_arc(s::SimpleNet, id::Symbol)        = any(x -> x[:id] === id, arcs(s))
"""
$(TYPEDSIGNATURES)
"""
has_refP(s::SimpleNet, id::Symbol)       = any(x -> x[:id] === id, refplaces(s))
"""
$(TYPEDSIGNATURES)
"""
has_refT(s::SimpleNet, id::Symbol)       = any(x -> x[:id] === id, reftransitions(s))

"""
$(TYPEDSIGNATURES)
Return the place with `id` in net `s`.
"""
place(s::SimpleNet, id::Symbol)      =      s.place[findfirst(x -> x[:id] === id, places(s))]
"""
$(TYPEDSIGNATURES)
"""
transition(s::SimpleNet, id::Symbol) = s.transition[findfirst(x -> x[:id] === id, transitions(s))]
"""
$(TYPEDSIGNATURES)
"""
arc(s::SimpleNet, id::Symbol)               = s.arc[findfirst(x -> x[:id] === id, arcs(s))]
"""
$(TYPEDSIGNATURES)
"""
refplace(s::SimpleNet, id::Symbol)      =    s.refP[findfirst(x -> x[:id] === id, refplaces(s))]
"""
$(TYPEDSIGNATURES)
"""
reftransition(s::SimpleNet, id::Symbol) =    s.refT[findfirst(x -> x[:id] === id, reftransitions(s))]


# All pnml nodes in IR have an `id`.
"""
$(TYPEDSIGNATURES)
"""
id(node::PnmlDict)::Symbol = node[:id]

"""
$(TYPEDSIGNATURES)
Return vector of place ids in `s`.
"""
place_ids(s::SimpleNet) = map(id, places(s)) 
"""
$(TYPEDSIGNATURES)
"""
transition_ids(s::SimpleNet) = map(id, transitions(s)) 
"""
$(TYPEDSIGNATURES)
"""
arc_ids(s::SimpleNet) = map(id, arcs(s)) 
"""
$(TYPEDSIGNATURES)
"""
refplace_ids(s::SimpleNet) = map(id, refplaces(s)) 
"""
$(TYPEDSIGNATURES)
"""
reftransition_ids(s::SimpleNet) = map(id, reftransitions(s)) 

#TODO: wrap arc?
"""
$(TYPEDSIGNATURES)
"""
source(arc)::Symbol = arc[:source]
"""
$(TYPEDSIGNATURES)
"""
target(arc)::Symbol = arc[:target]

"""
$(TYPEDSIGNATURES)
Return vector of arcs that have a source or target of transition `id`.
"""
all_arcs(s::SimpleNet, id::Symbol) = filter(a->source(a)===id || target(a)===id, arcs(s))

"""
$(TYPEDSIGNATURES)
Return vector of arcs that have a source of transition `id`.
"""
src_arcs(s::SimpleNet, id::Symbol) = filter(a->source(a)===id, arcs(s))

"""
$(TYPEDSIGNATURES)
Return vector of arcs that have a  target of transition `id`.
"""
tgt_arcs(s::SimpleNet, id::Symbol) = filter(a->target(a)===id, arcs(s))

"""
$(TYPEDSIGNATURES)

Remove reference nodes from arcs.
Design intent expects [`collapse_pages!`](@ref) to have
been applied so that everything is on one page.

# Examples
## Axioms
  1) All ids in a PNML.Document are unique in that they only have one instance in the XML.
  2) A chain of reference Places or Transitions always ends at a Place or Transition.
  3) All ids are valid.
"""
function deref! end
function deref!(s::SimpleNet)
    for a in arcs(s)
        while a[:source] ∈ refplace_ids(s)
            @show a[:source], deref_place(s, a[:source])
            a[:source] = deref_place(s, a[:source])
        end
        while a[:target] ∈ refplace_ids(s)
            @show a[:target], deref_place(s, a[:target])
            a[:target] = deref_place(s, a[:target])
        end
        while a[:source] ∈ reftransition_ids(s)
            @show a[:source], deref_transition(s, a[:source])
            a[:source] = deref_transition(s, a[:source])
        end
        while a[:target] ∈ reftransition_ids(s)
            @show a[:target], deref_transition(s, a[:target])
            a[:target] = deref_transition(s, a[:target])
        end        
    end
end

"""
$(TYPEDSIGNATURES)

Return id of referenced place.
"""
deref_place(s::SimpleNet, id::Symbol) =  refplace(s, id)[:ref]

"""
$(TYPEDSIGNATURES)

Return id of referenced transition.
"""
deref_transition(s::SimpleNet, id::Symbol) =  reftransition(s, id)[:ref]


#TODO  marking, inscription, condition, can be more complicated

"""
$(TYPEDSIGNATURES)

Return marking value of a place `p`.

# Examples

```jldoctest
julia> using PNML

julia> p = Dict(:marking => Dict(:value=>nothing));

julia> PNML.marking(p)
0

julia> p = Dict(:marking => Dict(:value=>12.34));

julia> PNML.marking(p)
12.34
```
"""
function marking end
function marking(p)::Number
    if !isnothing(p[:marking]) && !isnothing(p[:marking][:value])
        p[:marking][:value]
    else
        0
    end
end
marking(s::SimpleNet, p::Symbol) = marking(place(s,p))

"""
$(TYPEDSIGNATURES)

Return incription value of `arc`.
"""
function inscription end
function inscription(arc)::Number
    if !isnothing(arc[:inscription]) && !isnothing(arc[:inscription][:value])
        arc[:inscription][:value]
    else
        1
    end        
end
inscription(s::SimpleNet, a::Symbol) = inscription(arc(s,a))

#TODO: Specialize for stochastic pntd.
"""
Return condition value of `transition`.
"""
function condition end
function condition(transition)::Number
    if (!isnothing(transition[:condition]) &&
        !isnothing(transition[:condition][:text]) &&
        !isnothing(transition[:condition][:text][:content]))
        #TODO implement full structure handling
        rate = number_value(transition[:condition][:text][:content])
        isnothing(rate) ? 0 : rate
    else
        0
    end
end
condition(s::SimpleNet, t::Symbol) = condition(transition(s,t))

"""
$(TYPEDSIGNATURES)

Transition function of a Petri Net.
Each transition has an input vector and an output vector.
Each labelled vector is indexed by the place on the other end of the arc.
Values are inscriptions.
"""
function transition_function end
transition_function(s::SimpleNet) = transition_function(s, transition_ids(s))
transition_function(s::SimpleNet, v::Vector{Symbol}) =
    LVector( (; [t=>in_out(s,t) for t in v]...))

"""
$(TYPEDSIGNATURES)

Return tuple of input, output labelled vectors with key of place ids and
value of arc inscription's value. 
"""
function in_out(s::SimpleNet, t::Symbol)
    # Input arcs have this transition as the target.
    ins = (; [source(a)=>inscription(a) for a in tgt_arcs(s, t)]...)
    # Output arcs have this transition as the source.
    out = (; [target(a)=>inscription(a) for a in src_arcs(s, t)]...)
    (LVector(ins), LVector(out))
end    

"""
$(TYPEDSIGNATURES)
"""

function inoitialMarking end
initialMarking(s::SimpleNet) = initialMarking(s, place_ids(s))
initialMarking(s::SimpleNet, v::Vector{Symbol}) =
    LVector( (; [p=>marking(s,p) for p in v]...))

"""
$(TYPEDSIGNATURES)
Return a vector of condition values for net `s`.
"""
function conditions end
conditions(s::SimpleNet) = conditions(s, transition_ids(s))
conditions(s::SimpleNet, v::Vector{Symbol}) =
    LVector( (; [t=>condition(s,t) for t in v]...))
