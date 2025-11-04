using PNML, ..TestUtils, JET, OrderedCollections

#
# copied from pnmlframework-2.2.16/pnmlFw-Tests/XMLTestFilesRepository/Oracle
#
oracle = "data/XMLTestFilesRepository/Oracle"

println("\n-----------------------------------------")
println("full_coremodel.xml")
println("-----------------------------------------")
@testset let fname=joinpath(@__DIR__, oracle, "full_coremodel.xml")
    model = pnmlmodel(fname)::PnmlModel
    summary(stdout, model) #first(PNML.nets(model)))
    @show n = first(PNML.nets(model))
    @show n = PNML.flatten_pages!(n; verbose=true)
    @show vc = PNML.vertex_codes(n)
    @show vl = PNML.vertex_labels(n)
    for a in arcs(n)
        println(repr(a)," \t Edge ",
                    vc[PNML.source(a)], " -> ",  vc[PNML.target(a)], " or ",
                    vl[vc[PNML.source(a)]], " -> ",  vl[vc[PNML.target(a)]],
                    )
        end
    if !(narcs(n) > 0 && nplaces(n) > 0 && ntransitions(n) > 0)
        @test_throws ArgumentError PNML.metagraph(n)
    else
        @show PNML.metagraph(n)
    end
end

println("\n-----------------------------------------")
println("full_ptnet.xml")
println("-----------------------------------------")
@testset let fname=joinpath(@__DIR__, oracle, "full_ptnet.xml")
    model = pnmlmodel(fname)::PnmlModel
    summary(stdout, model) #first(PNML.nets(model)))
    n = first(PNML.nets(model))
    n = PNML.flatten_pages!(n)
    @show vc = PNML.vertex_codes(n)
    @show vl = PNML.vertex_labels(n)
     if !(narcs(n) > 0 && nplaces(n) > 0 && ntransitions(n) > 0)
        @test_throws ArgumentError PNML.metagraph(n)
    else
        @show PNML.metagraph(n)
    end
end

println("\n-----------------------------------------")
println("full_sn.xml") # modified
println("-----------------------------------------")
# finiteenumeration
@testset let fname=joinpath(@__DIR__, oracle, "full_sn.xml")
    model = pnmlmodel(fname)::PnmlModel
    summary(stdout, model) #first(PNML.nets(model)))
    n = first(PNML.nets(model))
    n = PNML.flatten_pages!(n)
    @show vc = PNML.vertex_codes(n)
    @show vl = PNML.vertex_labels(n)
    if !(narcs(n) > 0 && nplaces(n) > 0 && ntransitions(n) > 0)
        @test_throws ArgumentError PNML.metagraph(n)
    else
        @show PNML.metagraph(n)
    end
end

println("\n-----------------------------------------")
println("full_hlpn.xml") # modified
println("-----------------------------------------")
@testset let fname=joinpath(@__DIR__, oracle, "full_hlpn.xml")
    model = pnmlmodel(fname)::PnmlModel
    summary(stdout, model) #first(PNML.nets(model)))
    n = first(PNML.nets(model))
    n = PNML.flatten_pages!(n)
    @show vc = PNML.vertex_codes(n)
    @show vl = PNML.vertex_labels(n)
    if !(narcs(n) > 0 && nplaces(n) > 0 && ntransitions(n) > 0)
        @test_throws ArgumentError PNML.metagraph(n)
    else
        @show PNML.metagraph(n)
    end
end
