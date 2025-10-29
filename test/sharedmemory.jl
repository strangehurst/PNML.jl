using PNML, ..TestUtils, JET, OrderedCollections
println("-----------------------------------------")
println("SharedMemory.pnml")
println("-----------------------------------------\n")
@testset let fname=joinpath(@__DIR__, "data", "SharedMemory.pnml")
    model = pnmlmodel(fname)::PnmlModel
    summary(stdout, model)
    #TODO more tests
end

println("-----------------------------------------")
println("SharedMemory-Hlpn.pnml") # modified
println("-----------------------------------------\n")
@testset let fname=joinpath(@__DIR__, "data", "SharedMemory-Hlpn.pnml")
    model = pnmlmodel(fname)::PnmlModel
    summary(stdout, model)
    #TODO more tests
end
