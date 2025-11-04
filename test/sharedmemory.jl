using PNML, ..TestUtils, JET, OrderedCollections
println("\n-----------------------------------------")
println("SharedMemory.pnml")
println("-----------------------------------------")
@testset let fname=joinpath(@__DIR__, "data", "SharedMemory.pnml")
    model = pnmlmodel(fname)::PnmlModel
    summary(stdout, model)
    n = first(PNML.nets(model))
     n = PNML.flatten_pages!(n)
   @show vc = PNML.vertex_codes(n)
    @show vl = PNML.vertex_labels(n)
    if !(narcs(n) > 0 && nplaces(n) > 0 && ntransitions(n) > 0)
        @test_throws ArgumentError PNML.metagraph(n)
    else
        @show PNML.metagraph(n)
    end
    #TODO more tests
end

println("\n-----------------------------------------")
println("SharedMemory-Hlpn.pnml") # modified
println("-----------------------------------------")
@testset let fname=joinpath(@__DIR__, "data", "SharedMemory-Hlpn.pnml")
    model = pnmlmodel(fname)::PnmlModel
    summary(stdout, model)
    n = first(PNML.nets(model))
    n = PNML.flatten_pages!(n)
    @show vc = PNML.vertex_codes(n)
    @show vl = PNML.vertex_labels(n)
    if !(narcs(n) > 0 && nplaces(n) > 0 && ntransitions(n) > 0)
        @test_throws ArgumentError PNML.metagraph(n)
    else
        @show PNML.metagraph(n)
    end
    #TODO more tests
end
