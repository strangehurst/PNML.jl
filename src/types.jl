

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

"""
Given a PnmlDict of a pnml 'net' element, assume there is only one page.
"""
SimpleNet(net) = SimpleNet(net[:id], collapse_pages(net))
SimpleNet(id, collapsed) = SimpleNet( id, collapsed[:places], collapsed[:trans], collapsed[:arcs])

#= What are the characteristics of a SimpleNet?

Assumptions about labels:
 place has marking
 transition has condition
 arc has source, target, inscription

marking isa initialMarking, has an integer value representing tokens. Default 0.
inscription has an integer value. Default 1.
condition may have a text value. #TODO what to put here?
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

#TODO: wrap arc?
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

function inscription(arc)::Integer
    if !isnothing(arc[:inscription]) && !isnothing(arc[:inscription][:value])
        arc[:inscription][:value]
    else
        1
    end        
end

#TODO: Return something more useful in Julia than a string!
function condition(transition)::Maybe{String}
    if !isnothing(transition[:condition]) && !isnothing(transition[:condition][:text])
        transition[:condition][:text][:content]
    else
        nothing
    end
end

"""
Maybe of type `T` or nothing.
"""
const Maybe{T} = Union{T, Nothing}

