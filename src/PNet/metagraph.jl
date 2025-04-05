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
