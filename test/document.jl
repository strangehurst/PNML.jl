using PNML, ..TestUtils, JET

@testset "Show" begin
    node = xmlroot("""<?xml version="1.0"?>
        <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
          <net id="smallnet" type="http://www.pnml.org/version-2009/grammar/ptnet">
          <name> <text>P/T Net with one place</text> </name>
            <page id="page0">
              <name> <text>page name</text> </name>
              <graphics><offset x="0" y="0"/></graphics>
              <toolspecific tool="unknowntool" version="1.0"><atool x="0"/></toolspecific>
              <text>net5 declaration label</text>
              <graphics><offset x="0" y="0"/></graphics>
              <toolspecific tool="unknowntool" version="1.0"><atool x="0"/></toolspecific>

              <place id="place1">
                <name> <text>Some place</text> </name>
                <initialMarking> <text>100</text> </initialMarking>
              </place>
              <transition id="transition1">
                <name> <text>Some transition </text> </name>
              </transition>
              <arc id="arc1" source="transition1" target="place1">
                <inscription> <text> 12 </text> </inscription>
              </arc>
              <arc id="arc2" source="place1" target="transition1">
                <inscription> <text> 13 </text> </inscription>
              </arc>
            </page>
          </net>
        </pnml>
        """)
    model = parse_pnml(node)

    @test model isa PnmlModel
end

@testset "Document & ID Registry" begin
    emptypage = xmlroot("""<?xml version="1.0"?>
    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
      <net id="net" type="pnmlcore"> <page id="page"/> </net>
    </pnml>
    """)
    @test_logs(match_mode=:all, parse_pnml(emptypage) )

    @test_opt target_modules=(@__MODULE__,) parse_pnml(emptypage)
    @test_call target_modules=target_modules parse_pnml(emptypage)

    #TODO ===============================================
    #=
    Create a tuple of ID Registries of the same shape as the nets of the model.
    =#
    #TODO ===============================================
end

@testset "multiple net type" begin
    model = @test_logs(match_mode=:all, parse_str("""
    <?xml version="1.0"?>
    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
      <net id="net1" type="http://www.pnml.org/version-2009/grammar/ptnet">
        <name><text>net1</text></name>
        <page id="page1"/>
      </net>
      <net id="net2" type="pnmlcore"> <name><text>net2</text></name> <page id="page2"/> </net>
      <net id="net3" type="ptnet"> <name><text>net3</text></name> <page id="page3"/> </net>
      <net id="net4" type="hlcore"> <name><text>net4</text></name> <page id="page4"/> </net>
      <net id="net5" type="pt_hlpng"> <name><text>net5</text></name> <page id="page5"/> </net>
    </pnml>
    """))

    @test PNML.namespace(model) == "http://www.pnml.org/version-2009/grammar/pnml"
    @test PNML.regs(model) isa Vector{PnmlIDRegistry}
    @test length(PNML.regs(model)) == length(PNML.nets(model))

    modelnets = PNML.nets(model)::Tuple
    @test length(modelnets) == 5

    for net in modelnets
        ntup = PNML.find_nets(model, net)
        t = PNML.nettype(net)
        @test PNML.name(net) == string(pid(net)) # true by special construction
        for n in ntup
            @test t === PNML.nettype(n)
        end
    end

    @testset "model net $pt" for pt in [:ptnet, :pnmlcore, :hlcore, :pt_hlpng,
                                        :hlnet, :symmetric, :continuous]
        @test_opt  PNML.find_nets(model, pt)
        @test_call PNML.find_nets(model, pt)

        for (l,m,r) in zip(PNML.find_nets(model, pt),
                           PNML.find_nets(model, pnmltype(pt)),
                           PNML.find_nets(model, string(pt)))
            @test l === m === r
            @test l.type === m.type ===  r.type === pnmltype(pt)
        end
    end

    # First use is here, so test mechanism here.
    @test PNML.ispid(:net1)(:net1)

    @test PNML.find_net(model, :net1) isa PnmlNet
    @test PNML.find_net(model, :net2) isa PnmlNet
    @test PNML.find_net(model, :net3) isa PnmlNet
    @test PNML.find_net(model, :net4) isa PnmlNet
    @test PNML.find_net(model, :net5) isa PnmlNet

    @test_call PNML.find_net(model, :net1)
    @test_opt  PNML.find_net(model, :net1)
end

@testset "empty page" begin
    @test parse_str("""<?xml version="1.0"?>
        <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
          <net id="net" type="pnmlcore"><page id="emptypage"> </page></net>
        </pnml>
        """) isa PnmlModel
end
