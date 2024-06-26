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
    println("\nmetagraph $(pntd(net)) $(pid(net))")
    if !(narcs(net) > 0 && nplaces(net) > 0 && ntransitions(net) > 0)
        @warn "$(pntd(net)) id = $(pid(net)) is not complete: " *
            "narcs = $(narcs(net)) nplaces = $(nplaces(net)) ntransitions = $(ntransitions(net))"
            # net
        return nothing
    end

    # map pnml id symbol to vertex code.
    @show vc = vertex_codes(net) # inverse is vertex_labels(net)

    # Create a directed graph from every arc in the petri net graph.
    @show graph = SimpleDiGraphFromIterator(Edge(vc[source(a)] => vc[target(a)]) for a in arcs(net))
    @show Graphs.nv(graph) Graphs.ne(graph)

    # Map id to (vertex code, label).
    vertexdata = Dict{Symbol, Tuple{Int, Union{Place, Transition}}}()
    for p in places(net)
        vertexdata[pid(p)] = (vc[pid(p)], p)
    end
    for t in transitions(net)
        vertexdata[pid(t)] = (vc[pid(t)], t)
    end
    @show vertexdata
    @assert length(vertexdata) == Graphs.nv(graph)
    # Map from (src,dst) to arc. Uses pid, not vertex codes of graph.
    edgedata = Dict((source(a), target(a)) => a for a in arcs(net))
    @show edgedata
    @assert length(edgedata) == Graphs.ne(graph) #

    vl = vertex_labels(net)
    @show vl
    @assert length(vl) == Graphs.nv(graph) == length(vc)

    MetaGraph(graph, vl, vertexdata, edgedata, PNML.name(net),
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
