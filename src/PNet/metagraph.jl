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
    metagraph(::PnmlNet) -> MetaGraph

Return MetaGraph instance based on a `SimpleDiGraph` with PNML nodes attached to vertices and edges.
"""
function metagraph end

metagraph(pn::AbstractPetriNet) = metagraph(pnmlnet(pn))

function metagraph(net::PnmlNet)
    # map pnml id symbol to vertex code.
    vc = vertex_codes(net) # inverse is vertex_labels(net)

    # Create a directed graph from every arc in the petri net graph.
    graph = SimpleDiGraphFromIterator(Edge(vc[source(a)] => vc[target(a)]) for a in arcs(net))

    # Map id to (vertex code, label).
    vertexdata = Dict{Symbol, Tuple{Int, Union{Place, Transition}}}()
    for p in places(net)
        vertexdata[pid(p)] = (vc[pid(p)], p)
    end
    for t in transitions(net)
        vertexdata[pid(t)] = (vc[pid(t)], t)
    end

    # Map from (src,dst) to arc. Uses pid, not vertex codes of graph.
    edgedata = Dict((source(a), target(a)) => a for a in arcs(net))

    MetaGraph(graph, vertex_labels(net), vertexdata, edgedata, PNML.name(net),
                edge_data -> 1.0, 1.0) # weights
end

# Some helpers for metagraph. Will be useful in validating.
# pnml id symbol converted to/from vertex code.
vertex_codes(n::PnmlNet)  = Dict(s=>i for (i,s) in enumerate(union(place_idset(n), transition_idset(n))))
vertex_labels(n::PnmlNet) = Dict(i=>s for (i,s) in enumerate(union(place_idset(n), transition_idset(n))))

vertexdata(net::PnmlNet) = begin
    vcode = vertex_codes(net)
    vdata = Dict{Symbol, Tuple{Int, Union{Place, Transition}}}()
    for p in places(net)
        vdata[pid(p)] = (vcode[pid(p)], p)
    end
    for t in transitions(net)
        vdata[pid(t)] = (vcode[pid(t)], t)
    end
    return vdata
end
