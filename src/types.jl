

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
find_nets(d, type::AbstractString) = find_nets(d, default_pntd_map[type])
find_nets(d, type::Symbol) = filter(n->n[:type] === type, d.nets)


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

"Given a PnmlDict of a pnml 'net' element, assume there is only one page."
SimpleNet(p) = SimpleNet(p[:id],
                         p[:pages][begin][:places],
                         p[:pages][begin][:trans],
                         p[:pages][begin][:arcs])

#= What are the characteristics of a SimpleNet?

Assumptions about labels:
 place has marking
 transition has condition
 arc has source, target, inscription

marking isa initialMarking, has an integer value representing tokens. Default 0.
inscription has an integer value. Default 1.
condition mayhave a text value. #TODO what to put here?
=#


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

#TODO: wrap arc 
source(arc)::Symbol = arc[:source]
target(arc)::Symbol = arc[:target]

#TODO  marking, inscription, condition, can be more  complicated
function marking(p)::Integer
    if !isnothing(p[:marking]) && !isnothing(p[:marking][:value])
        p[:marking][:value]
    else
        0
    end
end

function inscription(a)::Integer
    if !isnothing(a[:inscription]) && !isnothing(a[:inscription][:value])
        a[:inscription][:value]
    else
        1
    end        
end

#TODO: return something more useful in Julia than a string
function condition(trans)::Maybe{String}
    if !isnothing(trans[:condition]) && !isnothing(trans[:condition][:text])
        trans[:condition][:text][:content]
    else
        nothing
    end
end

"maybe of type `T` or nothing"
const Maybe{T} = Union{Nothing, T}

