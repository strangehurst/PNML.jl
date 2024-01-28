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
    # map pnml id symbol to vertex code.
    vc = vertex_codes(pnmlnet(pn)) # inverse is vertex_labels(pnmlnet(pn))

    # Create a directed graph from every arc in the petri net graph.
    graph = SimpleDiGraphFromIterator(Edge(vc[source(a)] => vc[target(a)]) for a in arcs(pn))

    # Map id to (vertex code, label).
    vertexdata = Dict{Symbol, Tuple{Int, Union{Place, Transition}}}()
    for p in places(pn)
        vertexdata[pid(p)] = (vc[pid(p)], p)
    end
    for t in transitions(pn)
        vertexdata[pid(t)] = (vc[pid(t)], t)
    end

    # Map from (src,dst) to arc. Uses pid, not vertex codes of graph.
    edgedata = Dict((source(a), target(a)) => a for a in arcs(pn))

    MetaGraph(graph, vertex_labels(pnmlnet(pn)), vertexdata, edgedata, PNML.name(pn),
                edge_data -> 1.0, 1.0) # weights
end
