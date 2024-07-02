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
    vcode  = vertex_codes(net) # inverse is vertex_labels(net)
    vlabel = vertex_labels(net)
    #@show vcode vlabel
    @assert length(vlabel) == length(vcode)

    # Create a directed graph from every arc in the petri net graph.
    graph = SimpleDiGraphFromIterator(Edge(vcode[source(a)] => vcode[target(a)]) for a in arcs(net))
    @assert length(vcode) == Graphs.nv(graph)

    # Map place/pransition pid to (vertex code, label).
    vdata = Dict{Symbol, Tuple{Int, Union{Place, Transition}}}()
    vertex_data!(vdata, net, vcode)
    @show vdata
    @assert length(vdata) == Graphs.nv(graph)

    # Map from (src,dst) to arc. Uses pid, not vertex codes of graph.
    edgedata = Dict((source(a), target(a)) => a for a in arcs(net))
    @show edgedata
    @assert length(edgedata) == Graphs.ne(graph)

    MetaGraph(graph, vlabel, vdata, edgedata, PNML.name(net), edge_data -> 1.0, 1.0)
end

"pnml id symbol mapped to graph vertex code."
vertex_codes(n::PnmlNet)  = Dict(s=>i for (i,s) in enumerate(union(place_idset(n), transition_idset(n))))
"graph vertex code mapped to pnml id symbol."
vertex_labels(n::PnmlNet) = Dict(i=>s for (i,s) in enumerate(union(place_idset(n), transition_idset(n))))

"Fill dictionary where keys are pnml ids, values are tuples of vertex code, place or transition."
function vertex_data!(vdata::Dict{Symbol, Tuple{Int, Union{Place, Transition}}},
                     net::PnmlNet,
                     vcode)
    for p in places(net)
        vdata[pid(p)] = (vcode[pid(p)], p)
    end
    for t in transitions(net)
        vdata[pid(t)] = (vcode[pid(t)], t)
    end
    return vdata
end
