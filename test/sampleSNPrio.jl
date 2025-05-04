using PNML, ..TestUtils, JET, OrderedCollections, AbstractTrees
#
# Read a SymmetricNet with partitions, tuples from pnmlframework test file.
# Note that this model is also included in the part 2 of the ISO standard as informative.
#
println("-----------------------------------------")
println("sampleSNPrio.pnml")
println("-----------------------------------------\n"); flush(stdout)
@testset let fname=joinpath(@__DIR__, "data", "sampleSNPrio.pnml")
    #false &&
    model = pnmlmodel(fname)::PnmlModel
    #println("model = ", model) #!net = first(nets(model)) # Multi-net models not common in the wild.
    #@test PNML.verify(net; verbose=true)
    #TODO apply metagraph tools
    println(); flush(stdout)
end
