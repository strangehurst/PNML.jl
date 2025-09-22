using PNML, ..TestUtils, JET, OrderedCollections

println("\n-----------------------------------------")
println("test1.pnml")
println("-----------------------------------------\n")
@testset let fname=joinpath(@__DIR__, "../snoopy", "test1.pnml")
    # model = @test_logs(match_mode=:any,
    #     (:warn, "ignoring unexpected child of <condition>: 'name'"),
    #     (:warn, "parse unknown declaration: tag = unknowendecl, id = unk1, name = u"),
    #     pnmlmodel(fname)::PnmlModel)
    model = pnmlmodel(fname)::PnmlModel
    @show summary(first(PNML.nets(model)))
#     # println("----"^10); @show model; println("----"^10)
#     #!@show model
#     #~ repr tests everybody's show() methods. #! Errors exposed warrent test BEFORE HERE!
#     #!@test startswith(repr(model), "PnmlModel")

#     #@show map(pid, PNML.nets(model)); println()

#     for n in PNML.nets(model)
#         @with PNML.idregistry => PNML.registry_of(model, pid(n)) begin
#             #println("-----------------------------------------")
#             @test PNML.verify(n; verbose=false)
#             PNML.flatten_pages!(n; verbose=false)
#             @test PNML.verify(n; verbose=true))
#             #println("-----------------------------------------")
#             #println("FLATTENED NET")
#             #@show n
#             #println("-----------------------------------------")
#             Base.redirect_stdio(stdout=devnull, stderr=devnull) do
#             #Base.redirect_stdio(stdout=nothing, stderr=nothing) do #! debug
#                 #TODO use MetaGraph as base of a validation tool
#                 println("vertex_codes")
#                 @show vc = PNML.vertex_codes(n)
#                 @show vl = PNML.vertex_labels(n)
#                 println("-----------------------------------------")
#                 @show arcs(n)
#                 for a in arcs(n)
#                     @show a
#                     println("Edge ", vc[PNML.source(a)], " -> ",  vc[PNML.target(a)])
#                 end
#                 println("-----------------------------------------")
#                 if !(narcs(n) > 0 && nplaces(n) > 0 && ntransitions(n) > 0)
#                     @test_throws ArgumentError PNML.metagraph(n)
#                 else
#                     @show PNML.metagraph(n)
#                 end
#             end
#         end
#     end
    #println("\n-----------------------------------------")
end
