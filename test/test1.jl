using PNML, JET, OrderedCollections

include("TestUtils.jl")
using .TestUtils

println("\n-----------------------------------------")
println("test1.pnml")
println("-----------------------------------------\n")
@testset let fname=joinpath(@__DIR__, "data", "test1.pnml")
    # model = @test_logs(match_mode=:any,
    #     (:warn, "ignoring unexpected child of <condition>: 'name'"),
    #     (:warn, "parse unknown declaration: tag = unknowendecl, id = unk1, name = u"),
    #     pnmlmodel(fname)::PnmlModel)
    model = pnmlmodel(fname)::PnmlModel
    summary(stdout, model)

#     # println("----"^10); @show model; println("----"^10)
#     #!@show model
#     #~ repr tests everybody's show() methods. #! Errors exposed warrent test BEFORE HERE!
#     #!@test startswith(repr(model), "PnmlModel")

    @test map(pid, PNML.nets(model)) == (:net1,:net2,:net3,:net4,:net5,:net6,
                                            :net7,:net8,:net9,:net10,:net11);

    for n in PNML.nets(model)
        println("-----------------------------------------")
        println(summary(n))
        @test PNML.verify(n, false)
        PNML.flatten_pages!(n; verbose=false)
        @test PNML.verify(n, false)
        #Base.redirect_stdio(stdout=devnull, stderr=devnull) do
        Base.redirect_stdio(stdout=nothing, stderr=nothing) do #! debug
            #TODO use MetaGraph as base of a validation tool
            vc = PNML.vertex_codes(n)::AbstractDict
            vl = PNML.vertex_labels(n)::AbstractDict
            for a in arcs(n)
                println("Edge ",
                    vc[PNML.source(a)], " -> ",  vc[PNML.target(a)], " or ",
                    vl[vc[PNML.source(a)]], " -> ",  vl[vc[PNML.target(a)]],
                    )
            end
            if !(narcs(n) > 0 && nplaces(n) > 0 && ntransitions(n) > 0)
                @test_throws ArgumentError PNML.metagraph(n)
            else
                @test contains(sprint(show, PNML.metagraph(n)),
                    "Meta graph based on a Graphs.SimpleGraphs.SimpleDiGraph{Int64}")
            end
        end
    end
end
