using PNML, EzXML, ..TestUtils, JET, OrderedCollections, AbstractTrees

const pnmldoc = PNML.xmlroot("""<?xml version="1.0"?>
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
""") # shared by testsets

@testset "parse node level" begin
    # Do a full parse and maybe print the generated data structure.
    pnml_ir = @test_logs(match_mode=:all, parse_pnml(pnmldoc))
    @test pnml_ir isa PnmlModel

    for net in nets(pnml_ir)
        @test net isa PnmlNet
        @test pid(net) isa Symbol

        for page in pages(net)
            @test page isa Page
            @test @inferred(pid(page)) isa Symbol
            for p in places(page)
                @test p isa Place
                placeid = pid(p)
                @test placeid isa Symbol
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
            for decl in PNML.declarations(page)
                @test decl isa Declaration
                @test decl[:text] !== nothing || decl[:structure] !== nothing
            end
        end

        for decl in PNML.declarations(net)
            @test decl isa Declaration
            @test decl[:text] !== nothing || decl[:structure] !== nothing
        end
    end
end


# Read a SymmetricNet from www.pnml.com examples or MCC
@testset "AirplaneLD pnml file" begin
    println("\n","------------------------"^6)
    @show testfile = joinpath(@__DIR__, "data", "AirplaneLD-col-0010.pnml")

    model = parse_file(testfile)
    #!model = @test_logs(match_mode=:all, parse_file(testfile))
    @test model isa PnmlModel

    netvec = nets(model)
    @test netvec isa Tuple{Vararg{PnmlNet{<:PnmlType}}}
    @test length(netvec) == 1

    net = first(netvec)
    @test net isa PnmlNet{<:SymmetricNet}
    @test PNML.verify(net; verbose=true)

    @test pages(net) isa Base.Iterators.Filter
    @test only(allpages(net)) == only(pages(net))
    #todo compare pages(net) == allpages(net)
    @test firstpage(net) isa Page
    @test first(pages(net)) isa Page
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

    @test_call target_modules=target_modules parse_file(testfile)
    @test_call nets(model)
    @test !isempty(repr(PNML.netdata(net)))
    @test !isempty(repr(PNML.netsets(firstpage(net))))
    @show summary(PNML.netsets(firstpage(net)))

    #TODO apply metagraph tools
end

# Read a SymmetricNet with partitions from pnmlframework test files
@testset "sampleSNPrio pnml file" begin
    println("\n-----------------------------------------")
    @show testfile = joinpath(@__DIR__, "data", "sampleSNPrio.pnml")

    model = parse_file(testfile)::PnmlModel
    @show net = first(nets(model)) # Multi-net models not common.
    @test PNML.verify(net; verbose=true)
    #TODO apply metagraph tools
end

# Read a file
@testset "test1.pnml file" begin
    println("\n-----------------------------------------")
    println("test1.pnml")
    println("-----------------------------------------\n")
    model = @test_logs(match_mode=:any,
        (:warn, "ignoring unexpected child of <condition>: 'name'"),
        (:warn, "parse unknown declaration: tag = unknowendecl, id = unk1, name = u"),
        parse_file(joinpath(@__DIR__, "../snoopy", "test1.pnml")))
    # model = parse_file(joinpath(@__DIR__, "../snoopy", "test1.pnml"))
    println("-----------------------------------------")

    @test model isa PnmlModel
    @show model
    println("-----------------------------------------")
    println("-----------------------------------------")
    #~ repr tests everybody's show() methods. #! Errors exposed warrent test BEFORE HERE!
    @test startswith(repr(model), "PnmlModel")

    #@show [pid(x) for x in PNML.nets(model)]
    @show map(pid, PNML.nets(model)) # tuple
    println()
    for n in PNML.nets(model)
        println("-----------------------------------------"^3)
        @test PNML.verify(n); verbose=false
        PNML.flatten_pages!(n; verbose=false)
        @test PNML.verify(n; verbose=true)
        println("-----------------------------------------"^3)
        @show n
        println("-----------------------------------------"^3)
        Base.redirect_stdio(stdout=testshow, stderr=testshow) do
            #TODO use as base of a validation tool
            println("pagetree")
            PNML.pagetree(n)
            println("print_tree")
            AbstractTrees.print_tree(n)
            println("vertex_codes")
            vc = PNML.vertex_codes(n)
            vl = PNML.vertex_labels(n)
            println("vertexdata")
            vd = PNML.vertexdata(n)
            println()
            @show typeof(vd)
            @show keys(vd)
            map(println, values(vd))
            println("-----------------------------------------")
            for a in arcs(n)
                @show a
                println("Edge ", vc[PNML.source(a)], " -> ",  vc[PNML.target(a)])
            end
            @show PNML.metagraph(n)
        end
    end
    println("\n-----------------------------------------")
end
