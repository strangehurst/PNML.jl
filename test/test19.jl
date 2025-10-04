using PNML, ..TestUtils, JET, OrderedCollections

# from ePNK
println("-----------------------------------------")
println("test19.pnml") # modified
println("-----------------------------------------\n")
@testset let fname=joinpath(@__DIR__, "data/ePNK", "test19.pnml")
    model = pnmlmodel(fname)::PnmlModel
    # println("model = ", model) #! debug
end
