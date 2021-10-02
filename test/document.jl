
@testset "net type" begin
    # pnml with multiple nets.    
    str = """
    <?xml version="1.0"?><!-- https://github.com/daemontus/pnml-parser -->
    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
      <net id="net1" type="http://www.pnml.org/version-2009/grammar/ptnet"> <page id="page1"/> </net>
      <net id="net2" type="pnmlcore"> <page id="page2"/> </net>
      <net id="net3" type="ptnet"> <page id="page3"/> </net>
      <net id="net4" type="hlcore"> <page id="page4"/> </net>
      <net id="net5" type="pt_hlpng"> <page id="page5"/> </net>
    </pnml>
        """ 
    
    doc = PNML.Document(parse_doc(parsexml(str)))
    #printnode(doc.nets);println()
    v1 = PNML.find_nets(doc, :ptnet)
    printnode(v1, label="v1")
    foreach(v1) do net
        @test net[:type] === :ptnet
    end    
    v2 = PNML.find_nets(doc, "ptnet")
    printnode(v2, label="v2")
    foreach(v2) do net
        @test net[:type] === :ptnet
    end    
    
    @test v1 == v2
    @test length(v1) == 2
    
    v3 = PNML.find_nets(doc, :pnmlcore)
    printnode(v3, label="v3")
    foreach(v3) do net
        @test net[:type] === :pnmlcore
    end    
    
    @test !isempty(v3)
    @test v3 != v1
    
    @testset for t in [:ptnet, :pnmlcore, :hlcore, :pt_hlpng, :hlnet, :symmetric, :stochastic, :timednet]
        foreach(PNML.find_nets(doc, t)) do net
            @test net[:type] === t
        end
    end
end


@testset "net type" begin
    # pnml with multiple nets.    
    str = """
    <?xml version="1.0"?><!-- https://github.com/daemontus/pnml-parser -->
    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
        <net id="net0" type="pnmlcore">
            <page id="page0">
            <place id="p1"> <initialMarking> <text>1</text> </initialMarking> </place>
            <place id="p2"> <initialMarking> <text>2</text> </initialMarking> </place>
            <place id="p3"> </place>
            <transition id ="t1"> <condition><text>true</text></condition> </transition>
            <transition id ="t2"> <condition/> </transition>
            <arc id="a1" source="p1" target="t1"> <inscription/> </arc>
            <arc id="a2" source="p2" target="t1"> <inscription/> </arc>
            <arc id="a3" source="t1" target="p3"> <inscription/> </arc>
            <arc id="a4" source="p3" target="t2"> <inscription/> </arc>
            <arc id="a5" source="t2" target="p1"> <inscription/> </arc>
            <arc id="a6" source="t2" target="p2"> <inscription/> </arc>
            </page>
        </net>
    </pnml>
        """ 
    
    doc = PNML.Document(parse_doc(parsexml(str)))
    #printnode(doc.nets);println()
    v = PNML.find_nets(doc, :pnmlcore)
    @test !isempty(v)
    net = PNML.SimpleNet(v[begin])
    for p in PNML.places(net)
        #printnode(p; label="place")
        @test PNML.has_place(net, p[:id])
        @test p == PNML.place(net, p[:id])
        @test PNML.id(p) ===  p[:id]
        @test_throws ArgumentError PNML.place(net, :bogus)
        println("place $(PNML.id(p)) $(PNML.marking(p))")
    end
    for t in PNML.transitions(net)
        #printnode(t; label="transition")
        @test PNML.has_transition(net, t[:id])
        @test t == PNML.transition(net, t[:id])
        @test PNML.id(t) ===  t[:id]
        @test_throws ArgumentError PNML.transition(net, :bogus)
        println("transition $(PNML.id(t)) $(PNML.condition(t))")
    end
    for a in PNML.arcs(net)
        #printnode(a, label="arc")
        @test PNML.has_arc(net, a[:id])
        @test a == PNML.arc(net, a[:id])
        @test PNML.id(a) ===  a[:id]
        @test_throws ArgumentError PNML.arc(net, :bogus)
        println("arc $(PNML.id(a)) s:$(PNML.source(a)) t:$(PNML.target(a)) $(PNML.inscription(a))")
    end
    
    #dump(net)
end
