

"""
Wrap the collection of PNML nets from a single XML tree.
"""
struct Document{N,X}
    nets::N
    xml::X
end

Document(p) = Document(p[:nets],p[:xml])

"Return nets of 'd' matching the given pntd 'type'."
function find_nets end
find_nets(d::Document, type::AbstractString) = find_nets(d, default_pntd_map[type])
find_nets(d::Document, type::Symbol) = filter(n->n[:type] === type, d.nets)
first_net(d::Document) = first(d.nets)

"""
SimpleNet wraps the 'place', 'transition' & "arc" collections of a single page.

Omits the page level of the pnml-defined hierarchy, and
all labels at the merged net/page level of pnml.

# TODO: Support labels? Some, all, non-standard? 

A multi-page net can be collpsed by removing referenceTransitions & referencePlaces,
and merging labels of net and all pages.
"""
struct SimpleNet{P,T,A}
    id::Symbol 
    place::P
    transition::T
    arc::A
end


#TODO: Transform Vector{Any} to more specific types. Benchmark first.
#TODO: Maybe using more wrappers. Starts needing pntd-specific types.

"""
Given a PnmlDict of a pnml 'net' element, assume there is only one page.
"""
SimpleNet(doc::Document) = SimpleNet(first_net(doc))
SimpleNet(net) = SimpleNet(net[:id], collapse_pages(net))
SimpleNet(id::Symbol, collapsed) = SimpleNet( id, collapsed[:places], collapsed[:trans], collapsed[:arcs])
SimpleNet(str::AbstractString) = SimpleNet(Document(parse_doc(parsexml(str))))

#= What are the characteristics of a SimpleNet?

Assumptions about labels:
 place has marking
 transition has condition
 arc has source, target, inscription

marking isa initialMarking, has an integer value representing tokens. Default 0.
inscription has an integer value. Default 1.
condition may have a text value. #TODO what to put here?
=#

"""
    collapse_pages(net)

Return NamedTuple holding merged page content.
Start with simplest case of assuming that only the first page is meaningful.
Collect places, transitions and arcs. #TODO COLLECT LABELS
"""
function collapse_pages(net)
    (; :places => net[:pages][begin][:places],
        :trans => net[:pages][begin][:trans],
        :arcs  => net[:pages][begin][:arcs]) 
end

places(s::SimpleNet) = s.place
transitions(s::SimpleNet) = s.transition
arcs(s::SimpleNet) = s.arc

"Is there any place with 'id' in net 's'?"
has_place(s::SimpleNet, id::Symbol)      = any(x -> x[:id] === id, places(s))
has_transition(s::SimpleNet, id::Symbol) = any(x -> x[:id] === id, transitions(s))
has_arc(s::SimpleNet, id::Symbol)        = any(x -> x[:id] === id, arcs(s))

"Return the place with 'id' in net 's'."
place(s::SimpleNet, id::Symbol)      = s.place[findfirst(x -> x[:id] === id, places(s))]
transition(s::SimpleNet, id::Symbol) = s.transition[findfirst(x -> x[:id] === id, transitions(s))]
arc(s::SimpleNet, id::Symbol)        = s.arc[findfirst(x -> x[:id] === id, arcs(s))]


# All pnml nodes have an 'id'.
id(node)::Symbol = node[:id]

# Get vector of ids.
place_ids(s::SimpleNet) = map(id, places(s)) 
transition_ids(s::SimpleNet) = map(id, transitions(s)) 
arc_ids(s::SimpleNet) = map(id, arcs(s)) 


#TODO: wrap arc?
source(arc)::Symbol = arc[:source]
target(arc)::Symbol = arc[:target]

"Return vector of arcs that have a source or target of transition 'id'."
all_arcs(s::SimpleNet, id::Symbol) = filter(a->source(a)===id || target(a)===id, arcs(s))

"Return vector of arcs that have a source of transition 'id'."
src_arcs(s::SimpleNet, id::Symbol) = filter(a->source(a)===id, arcs(s))

"Return vector of arcs that have a  target of transition 'id'."
tgt_arcs(s::SimpleNet, id::Symbol) = filter(a->target(a)===id, arcs(s))

"#TODO Return inscription value"
inscription(a) = a[:inscription][:value]
    

#TODO  marking, inscription, condition, can be more complicated

"Return marking value of a place."
function marking(p)::Number
    if !isnothing(p[:marking]) && !isnothing(p[:marking][:value])
        p[:marking][:value]
    else
        0
    end
end
"Return marking value of place with id 'p'."
marking(s::SimpleNet, p::Symbol) = marking(place(s,p))

"Return incription value of an arc."
function inscription(arc)::Number
    if !isnothing(arc[:inscription]) && !isnothing(arc[:inscription][:value])
        arc[:inscription][:value]
    else
        1
    end        
end
"Return inscription value of an arc with id 'a'."
inscription(s::SimpleNet, a::Symbol) = inscription(arc(s,a))

#TODO: Return something more useful in Julia than a string!
#Return condition value of a transition."
function condition(transition)::Maybe{String}
    if !isnothing(transition[:condition]) && !isnothing(transition[:condition][:text])
        transition[:condition][:text][:content]
    else
        nothing
    end
end
"Return condition value of a transition with id 't'."
condition(s::SimpleNet, t::Symbol) = condition(transition(s,t))

"""
Transition function of a Petri Net.
Each transition has an input vector and an output vector.
Each vector is indexed by the place on the other end of the arc.
Values are inscriptions.
"""
transition_function(s::SimpleNet) = transition_function(s, transition_ids(s))
transition_function(s::SimpleNet,v::Vector{Symbol}) =
    LVector( (;[t=>in_out(s,t) for t in v]...))

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

conditions(s::SimpleNet) = conditions(s, transition_ids(s))
conditions(s::SimpleNet, v::Vector{Symbol}) =
    LVector( (; [t=>number_value(condition(s,t)) for t in v]...))
