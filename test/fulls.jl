using PNML, ..TestUtils, JET, OrderedCollections

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
