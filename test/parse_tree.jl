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
    empty!(PNML.TOPDECLDICTIONARY)
    # Do a full parse and maybe print the generated data structure.
    @show pnml_ir = parse_pnml(pnmldoc)
    @test pnml_ir isa PnmlModel

    for net in nets(pnml_ir)
        @test net isa PnmlNet
        println()
        @show pid(net)::Symbol
        #@show net
        map(println, PNML.declarations(net)) # Iterate over all declarations

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
            # for decl in PNML.declarations(page) #! we harvest all declarations as one thing
            #     @test decl isa Declaration
            #     @test decl[:text] !== nothing || decl[:structure] !== nothing
            # end
        end
    end
end


# Read a SymmetricNet from www.pnml.com examples or MCC
@testset "AirplaneLD pnml file" begin
    empty!(PNML.TOPDECLDICTIONARY)
    println("\n","------------------------"^6)
    println("------------------------"^6)
    println("------------------------"^6)
    println("------------------------"^6)
    println("------------------------"^6)
    println("------------------------"^6)
    testfile = joinpath(@__DIR__, "data", "AirplaneLD-col-0010.pnml")
    println(testfile)
    model = parse_file(testfile)
    #!model = @test_logs(match_mode=:all, parse_file(testfile))
    @test model isa PnmlModel

    netvec = nets(model)::Tuple{Vararg{PnmlNet{<:PnmlType}}}
    @test length(netvec) == 1

    net = first(netvec)::PnmlNet{<:SymmetricNet}
    # Need to set scoped value PNML.idregistry to value for net
    with(PNML.idregistry => PNML.registry_of(model, pid(net))) do
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
end

# Read a SymmetricNet with partitions from pnmlframework test files
false &&
@testset "sampleSNPrio pnml file" begin
    empty!(PNML.TOPDECLDICTIONARY)
    println("\n-----------------------------------------")
    println("sampleSNPrio.pnml")
    println("-----------------------------------------\n")

    model = parse_file(joinpath(@__DIR__, "data", "sampleSNPrio.pnml"))::PnmlModel
    @show net = first(nets(model)) # Multi-net models not common.
    @test PNML.verify(net; verbose=true)
    #TODO apply metagraph tools
end

# Read a file
@testset "test1.pnml file" begin
    empty!(PNML.TOPDECLDICTIONARY)
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
        with(PNML.idregistry => PNML.registry_of(model, pid(n))) do
            println("-----------------------------------------"^3)
            @test PNML.verify(n); verbose=false
            PNML.flatten_pages!(n; verbose=false)
            @test PNML.verify(n; verbose=true)
            println("-----------------------------------------"^3)
            println("FLATTENED NET")
            @show n
            println("-----------------------------------------"^3)
            Base.redirect_stdio(stdout=testshow, stderr=testshow) do
                #TODO use as base of a validation tool
                println("pagetree")
                PNML.pagetree(n)
                println("print_tree")
                AbstractTrees.print_tree(n)
                println("vertex_codes")
                @show vc = PNML.vertex_codes(n)
                @show vl = PNML.vertex_labels(n)
                println("vertexdata")
                @show vd = PNML.vertexdata(n)
                println()
                @show typeof(vd)
                @show keys(vd)
                map(println, values(vd))
                println("-----------------------------------------")
                for a in arcs(n)
                    @show a
                    println("Edge ", vc[PNML.source(a)], " -> ",  vc[PNML.target(a)])
                end
                println("-----------------------------------------")
                @show PNML.metagraph(n)
            end
        end
    end
    println("\n-----------------------------------------")
end
