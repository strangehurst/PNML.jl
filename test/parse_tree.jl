using PNML, ..TestUtils, JET, OrderedCollections

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

@testset "node level traversal" begin
    for net in nets(pnmlmodel(pnmldoc)::PnmlModel)
        @test net isa PnmlNet
        #println()
        #@show pid(net)::Symbol
        #@show net
        #map(println, PNML.declarations(PNML.decldict(net))) # Iterate over all declarations

        # we harvest all declarations as one thing
        @test decldict(net) isa DeclDict

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

    @test_call broken=false target_modules=target_modules pnmlmodel(testfile)
    @test_call nets(model)

    @test !isempty(repr(PNML.netdata(net)))
    @test !isempty(repr(PNML.netsets(firstpage(net))))

    summary(stdout, PNML.netsets(firstpage(net)))

    #TODO apply metagraph toolinfos
end
