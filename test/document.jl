header("DOCUMENT")

@testset "Show" begin
str =
    """
<?xml version="1.0"?><!-- https://github.com/daemontus/pnml-parser -->
<pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
  <net id="small-net" type="http://www.pnml.org/version-2009/grammar/ptnet">
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
        <inscription> <text> 13 </text> </inscription>
      </arc>
    </page>
  </net>
</pnml>
    """
    pnml_ir = parse_pnml(root(parsexml(str)); reg=PNML.IDRegistry())
    @show pnml_ir
end

@testset "Document & IDRegistry" begin
    str = """
    <?xml version="1.0"?>
    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
      <net id="net" type="pnmlcore"> <page id="page"/> </net>
    </pnml>
    """
    header("### Registry")
    reg = PNML.IDRegistry()
    @test !PNML.isregistered(reg, :net)
    @test :net ∉ reg.ids

    parse_pnml(root(parsexml(str)); reg)
    @show reg

    @test PNML.isregistered(reg, :net)
    @test :net ∈ reg.ids
end

@testset "multiple net type" begin
    str = """
    <?xml version="1.0"?>
    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
      <net id="net1" type="http://www.pnml.org/version-2009/grammar/ptnet"> <page id="page1"/> </net>
      <net id="net2" type="pnmlcore"> <page id="page2"/> </net>
      <net id="net3" type="ptnet"> <page id="page3"/> </net>
      <net id="net4" type="hlcore"> <page id="page4"/> </net>
      <net id="net5" type="pt_hlpng"> <page id="page5"/> </net>
    </pnml>
    """

    @show model = parse_str(str)
    #@show model

    v1 = PNML.find_nets(model, :ptnet)
    printnode(v1, label="v1")
    foreach(v1) do net
        @test net.type === PNML.pnmltype(:ptnet)
    end
    v2 = PNML.find_nets(model, "ptnet")
    printnode(v2, label="v2")
    foreach(v2) do net
        @test net.type === PNML.pnmltype(:ptnet)
    end

    @test v1 == v2
    @test length(v1) == 2

    v3 = PNML.find_nets(model, :pnmlcore)
    printnode(v3, label="v3")
    foreach(v3) do net
        @test net.type === PNML.pnmltype(:pnmlcore)
    end

    @test !isempty(v3)
    @test v3 != v1

    @testset for t in [:ptnet, :pnmlcore, :hlcore, :pt_hlpng, :hlnet, :symmetric, :stochastic, :timednet]
        foreach(PNML.find_nets(model, t)) do net
            @test net.type === PNML.pnmltype(t)
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

    @show model = parse_str(str)
end
