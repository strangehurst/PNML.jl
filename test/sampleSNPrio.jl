using PNML, ..TestUtils, JET, OrderedCollections, AbstractTrees
#
# Read a SymmetricNet with partitions & tuples from pnmlframework test file.
# NB: This model is from part 2 of the ISO 15909 standard as informative.
#
println("-----------------------------------------")
println("sampleSNPrio.pnml")
println("-----------------------------------------\n"); flush(stdout)
@testset let fname=joinpath(@__DIR__, "data", "sampleSNPrio.pnml")
    #false &&
    model = pnmlmodel(Context(), fname)::PnmlModel
    #println("model = ", model) #! debug
    #@test PNML.verify(net; verbose=true)
    #TODO apply metagraph tools
    println(); flush(stdout)
end
