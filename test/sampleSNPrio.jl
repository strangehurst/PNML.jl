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
    #@test PNML.verify(net; verbose=true)
end

println("-----------------------------------------")
println("Sudoku-COL-BN01.pnml")
println("-----------------------------------------\n")
# productsort, tuple, finiteintrangeconstant, or, and, equality
@testset let fname=joinpath(@__DIR__, "data", "MCC/Sudoku-COL-BN01.pnml")
    model = pnmlmodel(fname)::PnmlModel
    summary(stdout, model) #first(PNML.nets(model)))
end

#
# copied from pnmlframework-2.2.16/pnmlFw-Tests/XMLTestFilesRepository/Oracle
#
oracle = "data/XMLTestFilesRepository/Oracle"

println("-----------------------------------------")
println("full_coremodel.xml")
println("-----------------------------------------\n")
@testset let fname=joinpath(@__DIR__, oracle, "full_coremodel.xml")
    model = pnmlmodel(fname)::PnmlModel
    summary(stdout, model) #first(PNML.nets(model)))
end

println("-----------------------------------------")
println("full_ptnet.xml")
println("-----------------------------------------\n")
@testset let fname=joinpath(@__DIR__, oracle, "full_ptnet.xml")
    model = pnmlmodel(fname)::PnmlModel
    summary(stdout, model) #first(PNML.nets(model)))
end

println("-----------------------------------------")
println("full_sn.xml") # modified
println("-----------------------------------------\n")
# finiteenumeration
@testset let fname=joinpath(@__DIR__, oracle, "full_sn.xml")
    model = pnmlmodel(fname)::PnmlModel
    summary(stdout, model) #first(PNML.nets(model)))
end

println("-----------------------------------------")
println("full_hlpn.xml") # modified
println("-----------------------------------------\n")
@testset let fname=joinpath(@__DIR__, oracle, "full_hlpn.xml")
    model = pnmlmodel(fname)::PnmlModel
    summary(stdout, model) #first(PNML.nets(model)))
end

println("-----------------------------------------")
println("SharedMemory-Hlpn.pnml") # modified
println("-----------------------------------------\n")
@testset let fname=joinpath(@__DIR__, "data", "SharedMemory-Hlpn.pnml")
    model = pnmlmodel(fname)::PnmlModel
    summary(stdout, model) #first(PNML.nets(model)))
end

# from ePNK
println("-----------------------------------------")
println("test19.pnml") # modified
println("-----------------------------------------\n")
@testset let fname=joinpath(@__DIR__, "data/ePNK", "test19.pnml")
    model = pnmlmodel(fname)::PnmlModel
    # println("model = ", model) #! debug
end
