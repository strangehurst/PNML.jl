using PNML, EzXML, ..TestUtils, JET
using PNML: tag, pid, xmlroot, parse_pnml, PnmlModel, PnmlNet

@testset "Show" begin
str = """
<?xml version="1.0"?><!-- https://github.com/daemontus/pnml-parser -->
<pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
  <net id="small-net" type="http://www.pnml.org/version-2009/grammar/ptnet">
  <name> <text>P/T Net with one place</text> </name>
    <page id="page0">
      <name> <text>page name</text> </name>
      <graphics><offset x="0" y="0"/></graphics>
      <toolspecific tool="unknowntool" version="1.0"><atool x="0"/></toolspecific>
      <text>net5 declaration label</text>
      <graphics><offset x="0" y="0"/></graphics>
      <toolspecific tool="unknowntool" version="1.0"><atool x="0"/></toolspecific>
      <declaration>
        <structure>
            <declarations>
              <namedsort id="dot" name="Dot"><dot/></namedsort>
              <variabledecl id="varx" name="x"><usersort declaration="pro"/></variabledecl>
              <namedoperator id="id6" name="g">
                  <parameter>
                      <variabledecl id="id4" name="x"><integer/></variabledecl>
                      <variabledecl id="id5" name="y"><integer/></variabledecl>
                  </parameter>
                  <def>
                      <numberconstant value="1"><positive/></numberconstant>
                  </def>
                  <unknown/>
              </namedoperator>
              <unknowendecl id="unk1" name="u"><foo/></unknowendecl>
            </declarations>
        </structure>
      </declaration>

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
"""
    #
    model = @test_logs(match_mode=:all,
         (:warn, "found unexpected label of <page>: text"),
         #(:info, "parse_term kinds are Variable and Operator"),
         (:warn, r"^ignoring child of <namedoperator name=g, id=id6> with tag unknown, allowed: 'def', 'parameter'"),
         (:warn, r"^parse unknown declaration: tag = unknowendecl, id = unk1, name = u"),
        parse_pnml(xmlroot(str)))

    @test model isa PnmlModel
end

@testset "Document & ID Registry" begin
    emptypage = xmlroot("""<?xml version="1.0"?>
    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
      <net id="net" type="pnmlcore"> <page id="page"/> </net>
    </pnml>
    """)
    #reg = registry() #TODO registry tuple
    #@test !isregistered(reg, :net)
    #@test :net ∉ reg.ids

    @test_logs(match_mode=:all, parse_pnml(emptypage) )

    @test_opt target_modules=(@__MODULE__,) parse_pnml(emptypage)
    @test_call target_modules=target_modules parse_pnml(emptypage)

    #@test isregistered(reg, :net)
    #@test :net ∈ reg.ids

    #TODO ===============================================
    #=
    Create a tuple of ID Registries of the same shape as the nets of the model.
    =#
    #TODO ===============================================
end

@testset "multiple net type" begin
    str = """
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
    """

    model = @test_logs(match_mode=:all, parse_str(str))

    @test PNML.namespace(model) == "http://www.pnml.org/version-2009/grammar/pnml"
    @test PNML.regs(model) isa Vector{PnmlIDRegistry}

    modelnets = PNML.nets(model)
    @test modelnets isa Tuple
    @test length(collect(modelnets)) == 5

    for net in modelnets
        @test PNML.idregistry(net) isa PnmlIDRegistry
        t = PNML.nettype(net)
        ntup = PNML.find_nets(model, t)

        @test PNML.name(net) == string(pid(net))
        for n in ntup
            @test t === PNML.nettype(n)
        end
    end

    @testset "model net $pt" for pt in [:ptnet, :pnmlcore, :hlcore, :pt_hlpng,
                                        :hlnet, :symmetric, :continuous]
        @test_opt  pnmltype(pt)
        @test_call pnmltype(pt)
        @test_opt  PNML.find_nets(model, pt)
        @test_call PNML.find_nets(model, pt)

        for (l,m,r) in zip(PNML.find_nets(model, pt),
                           PNML.find_nets(model, pnmltype(pt)),
                           PNML.find_nets(model, string(pt)))
            @test l === m === r
            @test l.type === m.type ===  r.type === pnmltype(pt)
        end
    end


    # First use is here, so test mechanisim here.
    @test PNML.ispid(:net1)(:net1)

    @test PNML.find_net(model, :net1) isa PnmlNet
    @test PNML.find_net(model, :net2) isa PnmlNet
    @test PNML.find_net(model, :net3) isa PnmlNet
    @test PNML.find_net(model, :net4) isa PnmlNet
    @test PNML.find_net(model, :net5) isa PnmlNet

    @test_call PNML.find_net(model, :net1)
    @test_opt PNML.find_net(model, :net1)
end

@testset "empty page" begin
    str = """
    <?xml version="1.0"?>
    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
      <net id="net" type="pnmlcore">
        <page id="page">
        </page>
      </net>
    </pnml>
    """

    model = parse_str(str)
    @test model isa PnmlModel
end
