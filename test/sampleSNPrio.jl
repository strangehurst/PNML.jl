using PNML, ..TestUtils, JET, OrderedCollections
#
# Read a SymmetricNet with partitions & tuples from pnmlframework test file.
# NB: This model is from part 2 of the ISO 15909 standard as informative.
# From ePNK
println("\n-----------------------------------------")
println("sampleSNPrio.pnml")
println("-----------------------------------------"); flush(stdout)
# finiteenumeration, feconstant, partition, productsort, tuple,
@testset let fname=joinpath(@__DIR__, "data", "sampleSNPrio.pnml")
    #false &&
    model = pnmlmodel(fname)::PnmlModel
    summary(stdout, model) #first(PNML.nets(model)))
    n = first(PNML.nets(model))
    @show vc = PNML.vertex_codes(n)
    @show vl = PNML.vertex_labels(n)
    if !(narcs(n) > 0 && nplaces(n) > 0 && ntransitions(n) > 0)
        @test_throws ArgumentError PNML.metagraph(n)
    else
        @show PNML.metagraph(n)
    end
   #TODO more tests
    #TODO more tests
    #@test PNML.verify(net; verbose=true)
end

println("\n-----------------------------------------")
println("Sudoku-COL-BN01.pnml")
println("-----------------------------------------")
# productsort, tuple, finiteintrangeconstant, or, and, equality
@testset let fname=joinpath(@__DIR__, "data", "MCC/Sudoku-COL-BN01.pnml")
    model = pnmlmodel(fname)::PnmlModel
    summary(stdout, model) #first(PNML.nets(model)))
    n = first(PNML.nets(model))
    @show vc = PNML.vertex_codes(n)
    @show vl = PNML.vertex_labels(n)
    if !(narcs(n) > 0 && nplaces(n) > 0 && ntransitions(n) > 0)
        @test_throws ArgumentError PNML.metagraph(n)
    else
        @show PNML.metagraph(n)
    end
    #TODO more tests
end
