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
    n = first(PNML.nets(model))::PnmlNet
    n = PNML.flatten_pages!(n; verbose=true)::PnmlNet
    vc = PNML.vertex_codes(n)::AbstractDict
    vl = PNML.vertex_labels(n)::AbstractDict
    # for a in arcs(n)
    #     println("Edge ",
    #             vc[PNML.source(a)], " -> ",  vc[PNML.target(a)], " or ",
    #             vl[vc[PNML.source(a)]], " -> ",  vl[vc[PNML.target(a)]]
    #             )
    # end
    if !(narcs(n) > 0 && nplaces(n) > 0 && ntransitions(n) > 0)
        @test_throws ArgumentError PNML.metagraph(n)
    else
        @test contains(sprint(show, PNML.metagraph(n)),
            "Meta graph based on a Graphs.SimpleGraphs.SimpleDiGraph{Int64}")
    end
end

println("\n-----------------------------------------")
println("full_ptnet.xml")
println("-----------------------------------------")
@testset let fname=joinpath(@__DIR__, oracle, "full_ptnet.xml")
    model = pnmlmodel(fname)::PnmlModel
    summary(stdout, model) #first(PNML.nets(model)))
    n = first(PNML.nets(model))::PnmlNet
    n = PNML.flatten_pages!(n)::PnmlNet
    vc = PNML.vertex_codes(n)::AbstractDict
    vl = PNML.vertex_labels(n)::AbstractDict
     if !(narcs(n) > 0 && nplaces(n) > 0 && ntransitions(n) > 0)
        @test_throws ArgumentError PNML.metagraph(n)
    else
        @test contains(sprint(show, PNML.metagraph(n)),
            "Meta graph based on a Graphs.SimpleGraphs.SimpleDiGraph{Int64}")
    end
end

println("\n-----------------------------------------")
println("full_sn.xml") # modified
println("-----------------------------------------")
# finiteenumeration
@testset let fname=joinpath(@__DIR__, oracle, "full_sn.xml")
    model = @test_logs((:error, r".*inscription not provided for arc.*"),
                       (:error, r".*has neither a mark nor sorttype, use :dot.*"),
                       match_mode=:any,
        pnmlmodel(fname)::PnmlModel)
    summary(stdout, model) #first(PNML.nets(model)))
    n = first(PNML.nets(model))::PnmlNet
    n = PNML.flatten_pages!(n)::PnmlNet
    @test PNML.vertex_codes(n) isa AbstractDict
    @test PNML.vertex_labels(n) isa AbstractDict
    if !(narcs(n) > 0 && nplaces(n) > 0 && ntransitions(n) > 0)
        @test_throws ArgumentError PNML.metagraph(n)
    else
        @test contains(sprint(show, PNML.metagraph(n)),
           "Meta graph based on a Graphs.SimpleGraphs.SimpleDiGraph{Int64}")
    end
end

println("\n-----------------------------------------")
println("full_hlpn.xml") # modified
println("-----------------------------------------")
@testset let fname=joinpath(@__DIR__, oracle, "full_hlpn.xml")
    model = @test_logs((:error, r".*inscription not provided for arc.*"),
                       (:error, r".*has neither a mark nor sorttype, use :dot.*"),
                       match_mode=:any,
        pnmlmodel(fname)::PnmlModel)
    summary(stdout, model)
    n = first(PNML.nets(model))::PnmlNet
    n = PNML.flatten_pages!(n)::PnmlNet
    @test PNML.vertex_codes(n) isa AbstractDict
    @test PNML.vertex_labels(n) isa AbstractDict
    if !(narcs(n) > 0 && nplaces(n) > 0 && ntransitions(n) > 0)
        @test_throws ArgumentError PNML.metagraph(n)
    else
        @test contains(sprint(show, PNML.metagraph(n)),
            "Meta graph based on a Graphs.SimpleGraphs.SimpleDiGraph{Int64}")
    end
end
