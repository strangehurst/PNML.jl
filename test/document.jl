using PNML, EzXML, ..TestUtils, JET
using PNML: tag, pid, xmlroot, parse_pnml, PnmlModel,
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
    #model = @test_logs match_mode=:any begin  #! 1.10.beta broken here?
    #     (:warn,"unexpected child of <page>: text")
    #     (:warn,"namedoperator under development")
    #     (:warn,r"^element 'unknown' invalid as child of <namedoperator>.*")
    #     (:warn,r"^unknown declaration: unknowendecl unk1 u")
    #end parse_pnml(xmlroot(str), registry())
    #@test_logs broken=true (:warn,) #! 1.10.beta broken here?
    model = parse_pnml(xmlroot(str), registry())
    @test model isa PnmlModel
    Base.redirect_stdio(stdout=testshow, stderr=testshow) do
        @show model
    end
end
# @test_logs((:warn,""), expr)

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
    Base.redirect_stdio(stdout=testshow, stderr=testshow) do
        @show reg
    end
    @test isregistered(reg, :net)
    @test :net ∈ reg.ids
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
    model = @inferred parse_str(str)
    @test PNML.namespace(model) == "http://www.pnml.org/version-2009/grammar/pnml"
    @test PNML.idregistry(model) isa PnmlIDRegistry

    modelnets = PNML.nets(model)
    @test length(collect(modelnets)) == 5

    #println()
    for net in modelnets
        t = PNML.nettype(net)
        ntup = PNML.find_nets(model, t)

        #println(); dump(net); println()

        @test PNML.name(net) == string(pid(net))
        Base.redirect_stdio(stdout=testshow, stderr=testshow) do
            @show  pid(net) PNML.nettype.(ntup) pid.(ntup)
        end
        for n in ntup
            @test t === PNML.nettype(n)
        end
    end

    @testset "model net $pt" for pt in [:ptnet, :pnmlcore, :hlcore, :pt_hlpng]
        @test_opt pnmltype(pt)
        @test_call pnmltype(pt)
        for net in PNML.find_nets(model, pt)
            @test net.type === pnmltype(pt)
        end
        for net in PNML.find_nets(model, pnmltype(pt))
            @test net.type === pnmltype(pt)
        end
    end

    @testset for t in [:ptnet, :pnmlcore, :hlcore, :pt_hlpng, :hlnet, :symmetric]
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
