using PNML, ..TestUtils, JET, OrderedCollections, AbstractTrees
#
# Read a SymmetricNet with partitions & tuples from pnmlframework test file.
# NB: This model is from part 2 of the ISO 15909 standard as informative.
# From ePNK
println("-----------------------------------------")
println("sampleSNPrio.pnml")
println("-----------------------------------------\n"); flush(stdout)
@testset let fname=joinpath(@__DIR__, "data", "sampleSNPrio.pnml")
    #false &&
    model = pnmlmodel(fname)::PnmlModel
    # println("model = ", model) #! debug
    #@test PNML.verify(net; verbose=true)
    #TODO apply metagraph tools
    println(); flush(stdout)
end

#
# copied from pnmlframework-2.2.16/pnmlFw-Tests/XMLTestFilesRepository/Oracle
#
datapath = "data/XMLTestFilesRepository/Oracle"

println("-----------------------------------------")
println("full_coremodel.xml")
println("-----------------------------------------\n")
@testset let fname=joinpath(@__DIR__, datapath, "full_coremodel.xml")
    model = pnmlmodel(fname)::PnmlModel
    #println("model = ", model) #! debug
end

println("-----------------------------------------")
println("full_ptnet.xml")
println("-----------------------------------------\n")
@testset let fname=joinpath(@__DIR__, datapath, "full_ptnet.xml")
    model = pnmlmodel(fname)::PnmlModel
    #println("model = ", model) #! debug
end

println("-----------------------------------------")
println("full_sn.xml") # modified
println("-----------------------------------------\n")
@testset let fname=joinpath(@__DIR__, datapath, "full_sn.xml")
    model = pnmlmodel(fname)::PnmlModel
    #println("model = ", model) #! debug
end

println("-----------------------------------------")
println("full_hlpn.xml") # modified
println("-----------------------------------------\n")
@testset let fname=joinpath(@__DIR__, datapath, "full_hlpn.xml")
    model = pnmlmodel(fname)::PnmlModel
    println("model = ", model) #! debug
end

println(); flush(stdout)
