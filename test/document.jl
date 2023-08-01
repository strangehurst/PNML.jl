using PNML, EzXML, ..TestUtils, JET
using PNML: tag, pid, xmlnode, xmlroot, parse_pnml, PnmlModel,
    PnmlNet

@testset "Show" begin
str =
    """
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
      <arc source="transition1" target="place1" id="arc1">
        <inscription> <text>12 </text> </inscription>
      </arc>
      <arc source="place1" target="transition1" id="arc2">
        <inscription> <text> 13 </text> </inscription>
      </arc>
    </page>
  </net>
</pnml>
    """
    model = parse_pnml(xmlroot(str), registry())
    @test model isa PnmlModel
    #@show model
end

@testset "Document & ID Registry" begin
    str = """
    <?xml version="1.0"?>
    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
      <net id="net" type="pnmlcore"> <page id="page"/> </net>
    </pnml>
    """
    reg = registry()
    @test !isregistered(reg, :net)
    @test :net ∉ reg.ids

    parse_pnml(xmlroot(str), reg)
    @report_opt parse_pnml(xmlroot(str), reg)
    @test_call target_modules=target_modules parse_pnml(xmlroot(str), reg)
    #@show reg

    @test isregistered(reg, :net)
    @test :net ∈ reg.ids
end

@testset "multiple net type" begin
    str = """
    <?xml version="1.0"?>
    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
      <net id="net1" type="http://www.pnml.org/version-2009/grammar/ptnet">
        <page id="page1"/>
      </net>
      <net id="net2" type="pnmlcore"> <page id="page2"/> </net>
      <net id="net3" type="ptnet"> <page id="page3"/> </net>
      <net id="net4" type="hlcore"> <page id="page4"/> </net>
      <net id="net5" type="pt_hlpng"> <page id="page5"/> </net>
    </pnml>
    """
    model = @inferred parse_str(str)

    #println()
    for net in PNML.nets(model)
        t = PNML.nettype(net)
        ntup = PNML.find_nets(model, t)
        #@show  pid(net) t length(ntup) PNML.nettype.(ntup) pid.(ntup)
        for n in ntup
            @test t === PNML.nettype(n)
        end
    end
    v1 = @inferred Tuple{Vararg{PnmlNet}} PNML.find_nets(model, :ptnet)

    @test_opt pnmltype(:ptnet)
    @test_call pnmltype(:ptnet)
    for net in v1
        @test net.type === pnmltype(:ptnet)
    end
    v2 = @inferred Tuple{Vararg{PnmlNet}} PNML.find_nets(model, "ptnet")
    for net in v2
        @test net.type === PNML.PnmlTypeDefs.pnmltype(:ptnet)
    end

    @test v1 == v2
    @test length(v1) == 2

    v3 = PNML.find_nets(model, :pnmlcore)
    for net in v3
        @test net.type === pnmltype(:pnmlcore)
    end

    @test !isempty(v3)
    @test v3 != v1

    @testset for t in [:ptnet, :pnmlcore, :hlcore, :pt_hlpng, :hlnet, :symmetric, :stochastic, :timednet]
        for net in PNML.find_nets(model, t)
            @test net.type === pnmltype(t)
        end
    end
end

@testset "Empty" begin
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
