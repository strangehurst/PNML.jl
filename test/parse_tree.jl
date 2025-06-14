using PNML, ..TestUtils, JET, OrderedCollections, AbstractTrees

const pnmldoc = xml"""<?xml version="1.0"?>
<pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
  <net id="smallnet" type="http://www.pnml.org/version-2009/grammar/ptnet">
    <name> <text>P/T Net with one place</text> </name>
    <page id="page0">
      <place id="place1">
        <name> <text>Some place</text> </name>
        <initialMarking> <text>100</text> </initialMarking>
      </place>
      <transition id="transition1">
        <name> <text>Some transition </text> </name>
      </transition>
      <arc source="transition1" target="place1" id="arc1">
        <inscription> <text>12 </text> </inscription>
      </arc>
      <arc source="place1" target="transition1" id="arc2">
      </arc>
    </page>
  </net>
</pnml>
"""

@testset "parse node level" begin
    # Do a full parse and maybe print the generated data structure.
    pnml_ir = pnmlmodel(pnmldoc)
    @test pnml_ir isa PnmlModel

    for net in nets(pnml_ir)
        @test net isa PnmlNet
        #println()
        #@show pid(net)::Symbol
        #@show net
        #map(println, PNML.declarations(PNML.decldict(net))) # Iterate over all declarations

        for page in pages(net)
            @test page isa Page
            @test @inferred(pid(page)) isa Symbol
            for p in places(page)
                @test p isa Place
                placeid = pid(p)::Symbol
                @test has_place(page, placeid)
                @test pid(place(page, placeid)) === placeid
            end
            for transition in transitions(page)
                @test transition isa Transition
                @test pid(transition) isa Symbol
            end
            for arc in arcs(page)
                @test arc isa Arc
                @test pid(arc) isa Symbol
            end
            # for decl in PNML.decldict(page) #! we harvest all declarations as one thing
            #     @test decl isa Declaration
            #     @test decl[:text] !== nothing || decl[:structure] !== nothing
            # end
        end
    end
end

# Read a SymmetricNet from www.pnml.com examples or MCC
println("\n-----------------------------------------")
println("AirplaneLD-col-0010.pnml")
println("-----------------------------------------\n")
@testset let testfile=joinpath(@__DIR__, "data", "AirplaneLD-col-0010.pnml")
    println(testfile); flush(stdout)
    model = pnmlmodel(testfile)::PnmlModel
    #!model = @test_logs(match_mode=:all, pnmlmodel(testfile))

    netvec = nets(model)::Tuple{Vararg{PnmlNet{<:PnmlType}}}
    @test length(netvec) == 1

    net = first(netvec)::PnmlNet{<:SymmetricNet}

    @test PNML.verify(net; verbose=true)

    @test pages(net) isa Base.Iterators.Filter
    @test only(allpages(net)) == only(pages(net))
    #todo compare pages(net) == allpages(net)
    @test firstpage(net)::Page == first(pages(net))::Page
    @test PNML.npages(net) == 1

    @test !isempty(arcs(firstpage(net)))
    @test PNML.narcs(net) >= 0

    @test !isempty(places(firstpage(net)))
    @test PNML.nplaces(net) >= 0

    @test !isempty(transitions(firstpage(net)))
    @test PNML.ntransitions(net) >= 0
    @test transitions(firstpage(net)) == transitions(first(pages(net)))

    @test PNML.nreftransitions(net) == 0
    @test isempty(PNML.reftransitions(net))

    @test PNML.nrefplaces(net) == 0
    @test isempty(PNML.refplaces(net))

    @test_call target_modules=target_modules pnmlmodel(testfile)
    @test_call nets(model)

    @test !isempty(repr(PNML.netdata(net)))
    @test !isempty(repr(PNML.netsets(firstpage(net))))

    @show summary(PNML.netsets(firstpage(net)))

    #TODO apply metagraph tools
end

# println("\n-----------------------------------------")
# println("test1.pnml")
# println("-----------------------------------------\n")
# @testset let fname=joinpath(@__DIR__, "../snoopy", "test1.pnml")
#     # model = @test_logs(match_mode=:any,
#     #     (:warn, "ignoring unexpected child of <condition>: 'name'"),
#     #     (:warn, "parse unknown declaration: tag = unknowendecl, id = unk1, name = u"),
#     #     pnmlmodel(fname)::PnmlModel)
#     model = pnmlmodel(fname)::PnmlModel
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
#                 println("pagetree"); flush(stdout)
#                 PNML.pagetree(n)
#                 println("print_tree")
#                 AbstractTrees.print_tree(n)

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
#     #println("\n-----------------------------------------")
# end
