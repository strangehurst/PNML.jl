using Graphs: SimpleDiGraphFromIterator, Edge
using MetaGraphsNext: MetaGraph

"""
    metagraph(::AbstractPetriNet) -> graph

Return MetaGraph based on a `SimpleDiGraph` with PNML nodes attached to vertices and edges.
"""
function metagraph(pn::AbstractPetriNet)
    # pid symbol converted to/from vertex code for place/transition.
    vertex_code   = Dict(s=>i for (i,s) in enumerate(union(place_idset(pn), transition_idset(pn))))
    vertex_labels = Dict(i=>s for (i,s) in enumerate(union(place_idset(pn), transition_idset(pn))))

    # Create a directed graph from every arc (or edge) in the petri net graph.
    graph = SimpleDiGraphFromIterator(
                Edge(vertex_code[source(a)] => vertex_code[target(a)]) for a in arcs(pn))

    vertexdata = Dict{Symbol, Tuple{Int, Union{Place, Transition}}}() # map from pid
    for p in places(pn)
        vertexdata[pid(p)] = (vertex_code[pid(p)], p)
    end
    for t in transitions(pn)
        vertexdata[pid(t)] = (vertex_code[pid(t)], t)
    end

    # map from (src,dst) to arc,
    edgedata = Dict((source(a), target(a)) => a for a in arcs(pn))

    MetaGraph(graph, vertex_labels, vertexdata, edgedata, PNML.name(pn),
                edge_data -> 1.0, 1.0) # weights
end
