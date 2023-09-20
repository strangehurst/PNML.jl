using Graphs: SimpleDiGraphFromIterator, Edge
using MetaGraphsNext: MetaGraph

# TODO ============================
# TODO   Make into a functor?
# TODO
# TODO accessors from vertex, edge to PNML Nodes
# TODO petri net algorithms
# TODO
# TODO
# TODO
# TODO ============================

"""
    metagraph(::AbstractPetriNet) -> MetaGraph

Return MetaGraph instance based on a `SimpleDiGraph` with PNML nodes attached to vertices and edges.
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

    # Map from (src,dst) to arc. Uses pid, not vertex codes of graph.
    edgedata = Dict((source(a), target(a)) => a for a in arcs(pn))

    MetaGraph(graph, vertex_labels, vertexdata, edgedata, PNML.name(pn),
                edge_data -> 1.0, 1.0) # weights
end
