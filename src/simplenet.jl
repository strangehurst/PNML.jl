"""
    PNML.PetriNet

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

See [`parse_page`](@ref).

 [``](@ref)

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
SimpleNet wraps the `place`, `transition` & `arc` collections of a single page of one net.

Omits the page level of the pnml-defined hierarchy by collapsing down to one page.
A multi-page net can be collpsed by removing referenceTransitions & referencePlaces,
and merging pages into the first page. Only selected fields are merged.
"""
struct SimpleNet{P,T,A} <: PetriNet
    "Same as the XML attribute of the same name."
    id::Symbol
    
    place::P
    transition::T
    arc::A
end


SimpleNet(str::AbstractString) = SimpleNet(Document(str))
SimpleNet(doc::Document)       = SimpleNet(first_net(doc))

# Single network is the heart of PetriNet.
SimpleNet(net) = SimpleNet(net[:id], collapse_pages!(net))
SimpleNet(id::Symbol, collapsed) = SimpleNet(id,
                                             collapsed[:pages][1][:places],
                                             collapsed[:pages][1][:trans],
                                             collapsed[:pages][1][:arcs])
"""
"""
struct HLPetriNet{T} <: PetriNet
    id::Symbol
    net::PnmlDict
end
HLPetriNet(str::AbstractString) = HLPetriNet(Document(str))
HLPetriNet(doc::Document)       = HLPetriNet(first_net(doc))

# Single network is the heart of PetriNet.
HLPetriNet(net::PnmlDict) = HLPetriNet{typeof(net[:type])}(net[:id], collapse_pages!(net))

"""

    collapse_pages(net)

Return net with page content that may be repeated merged into the 1st page.
Note that refrence nodes are still present. They can be removed later
with [`deref`](@ref).

Start with simplest case of assuming that only the first page is meaningful.
Collect places, transitions and arcs.
#TODO COLLECT LABELS, DECLARATIONS
#TODO: Transform Vector{Any} to more specific types. Benchmark first.
#TODO: Maybe using more wrappers. Starts needing pntd-specific types.
"""
function collapse_pages!(net::PnmlDict)
    #net = s.
    @assert net[:tag] === :net
    page1 = net[:pages][1]
    pageN = @view net[:pages][2:end]
    for key in [:places, :trans, :arcs, :tools, :labels, :refT, :refP, :declarations]
        if !isnothing(page1[key]) #TODO requires first page to have non-empty key
            foreach(p->append!(page1[key], p[key]), pageN)
        end
    end
    net
end

function collapse_pages!(doc::PNML.Document)
    foreach(n->collapse_pages!(n), nets(doc))
end

places(s::SimpleNet) = s.place
transitions(s::SimpleNet) = s.transition
arcs(s::SimpleNet) = s.arc
refplaces(s::SimpleNet) = s.refP
reftransitions(s::SimpleNet) = s.refT

"Is there any place with `id` in net `s`?"
has_place(s::SimpleNet, id::Symbol)      = any(x -> x[:id] === id, places(s))
has_transition(s::SimpleNet, id::Symbol) = any(x -> x[:id] === id, transitions(s))
has_arc(s::SimpleNet, id::Symbol)        = any(x -> x[:id] === id, arcs(s))
has_refP(s::SimpleNet, id::Symbol)       = any(x -> x[:id] === id, refplaces(s))
has_refT(s::SimpleNet, id::Symbol)       = any(x -> x[:id] === id, reftransitions(s))

"Return the place with `id` in net `s`."
place(s::SimpleNet, id::Symbol)      =      s.place[findfirst(x -> x[:id] === id, places(s))]
transition(s::SimpleNet, id::Symbol) = s.transition[findfirst(x -> x[:id] === id, transitions(s))]
arc(s::SimpleNet, id::Symbol)               = s.arc[findfirst(x -> x[:id] === id, arcs(s))]
refplace(s::SimpleNet, id::Symbol)      =   s.place[findfirst(x -> x[:id] === id, refplaces(s))]
reftransition(s::SimpleNet, id::Symbol) = s.transition[findfirst(x -> x[:id] === id, reftransitions(s))]


# All pnml nodes have an `id`.
id(node)::Symbol = node[:id]

# Get vector of ids.
place_ids(s::SimpleNet) = map(id, places(s)) 
transition_ids(s::SimpleNet) = map(id, transitions(s)) 
arc_ids(s::SimpleNet) = map(id, arcs(s)) 
refplace_ids(s::SimpleNet) = map(id, refplaces(s)) 
reftransition_ids(s::SimpleNet) = map(id, reftransitions(s)) 

#TODO: wrap arc?
source(arc)::Symbol = arc[:source]
target(arc)::Symbol = arc[:target]

"Return vector of arcs that have a source or target of transition `id`."
all_arcs(s::SimpleNet, id::Symbol) = filter(a->source(a)===id || target(a)===id, arcs(s))

"Return vector of arcs that have a source of transition `id`."
src_arcs(s::SimpleNet, id::Symbol) = filter(a->source(a)===id, arcs(s))

"Return vector of arcs that have a  target of transition `id`."
tgt_arcs(s::SimpleNet, id::Symbol) = filter(a->target(a)===id, arcs(s))

"""
    deref(s::SimpeNet)

Remove reference nodes from arcs.
Design intent expects [`collapse_pages!`](@ref) to have
been applied.
"""
function deref(s::SimpleNet)
    for a in arcs(s)
        while a[:source] ∈  refplace_ids(s)
            a[:source] = refplace(s, a[:source])[:ref]
        end
        while a[:target] ∈  refplace_ids(s)
            a[:target] = refplace(s, a[:target])[:ref]
        end
        while a[:source] ∈  reftransitions_ids(s)
            a[:source] = reftransitions(s, a[:source])[:ref]
        end
        while a[:target] ∈  reftransition_ids(s)
            a[:target] = reftransitions(s, a[:target])[:ref]
        end
        
    end
end

#TODO  marking, inscription, condition, can be more complicated

"Return marking value of a place `P`."
function marking(p)::Number
    if !isnothing(p[:marking]) && !isnothing(p[:marking][:value])
        p[:marking][:value]
    else
        0
    end
end

"Return marking value of place with id `p`."
marking(s::SimpleNet, p::Symbol) = marking(place(s,p))

"Return incription value of `arc`."
function inscription(arc)::Number
    if !isnothing(arc[:inscription]) && !isnothing(arc[:inscription][:value])
        arc[:inscription][:value]
    else
        1
    end        
end

"Return inscription value of an arc with id `a`."
inscription(s::SimpleNet, a::Symbol) = inscription(arc(s,a))

#TODO: Return something more useful in Julia than a string!
#TODO: Specialize for stochastic pntd.
"Return condition value of `transition`."
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
"Return condition value of a transition with id `t`."
condition(s::SimpleNet, t::Symbol) = condition(transition(s,t))

"""
Transition function of a Petri Net.
Each transition has an input vector and an output vector.
Each labelled vector is indexed by the place on the other end of the arc.
Values are inscriptions.
"""
transition_function(s::SimpleNet) = transition_function(s, transition_ids(s))
transition_function(s::SimpleNet, v::Vector{Symbol}) =
    LVector( (; [t=>in_out(s,t) for t in v]...))

"""
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

initialMarking(s::SimpleNet) = initialMarking(s, place_ids(s))
initialMarking(s::SimpleNet, v::Vector{Symbol}) =
    LVector( (; [p=>marking(s,p) for p in v]...))

"Return a vector of condition values for net `s`."
conditions(s::SimpleNet) = conditions(s, transition_ids(s))
conditions(s::SimpleNet, v::Vector{Symbol}) =
    LVector( (; [t=>condition(s,t) for t in v]...))
