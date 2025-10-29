using PNML, ..TestUtils, JET, OrderedCollections
#
# Read a SymmetricNet with partitions & tuples from pnmlframework test file.
# NB: This model is from part 2 of the ISO 15909 standard as informative.
# From ePNK
println("-----------------------------------------")
println("sampleSNPrio.pnml")
println("-----------------------------------------\n"); flush(stdout)
# finiteenumeration, feconstant, partition, productsort, tuple,
@testset let fname=joinpath(@__DIR__, "data", "sampleSNPrio.pnml")
    #false &&
    model = pnmlmodel(fname)::PnmlModel
    summary(stdout, model) #first(PNML.nets(model)))
    #TODO more tests
    #TODO more tests
    #@test PNML.verify(net; verbose=true)
end

println("-----------------------------------------")
println("Sudoku-COL-BN01.pnml")
println("-----------------------------------------\n")
# productsort, tuple, finiteintrangeconstant, or, and, equality
@testset let fname=joinpath(@__DIR__, "data", "MCC/Sudoku-COL-BN01.pnml")
    model = pnmlmodel(fname)::PnmlModel
    summary(stdout, model) #first(PNML.nets(model)))
    #TODO more tests
end
