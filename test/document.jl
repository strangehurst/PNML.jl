
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
    
    doc = PNML.Document(parse_doc(EzXML.parsexml(str)))
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
    <?xml version="1.0"?>
    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
        <net id="net0" type="pnmlcore">
            <page id="page0">
            <place id="p1"> <initialMarking> <text>1</text> </initialMarking> </place>
            <place id="p2"> <initialMarking> <text>2</text> </initialMarking> </place>
            <place id="p3">
                <structure att1="doo"/>
                <frog name="hoppy" />
            </place>
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
    
    doc = PNML.Document(PNML.parse_doc(EzXML.parsexml(str)))
    printnode(doc.nets, label="net type")

    
    v = PNML.find_nets(doc, :pnmlcore)
    @test !isempty(v)
    @test v[begin] == PNML.first_net(doc)

    #@show typeof(PNML.parse_doc(EzXML.parsexml(str)))
    net1 = PNML.SimpleNet(doc)
    net = PNML.SimpleNet(v[begin]) #
    
    @test net == PNML.SimpleNet(PNML.first_net(doc))
    @test net == net1
    
    @show PNML.place_ids(net)
    @show PNML.transition_ids(net)
    @show PNML.arc_ids(net)

    for p in PNML.places(net)
        #printnode(p; label="place")
        @test PNML.has_place(net, p[:id])
        @test p == PNML.place(net, p[:id])
        @test PNML.id(p) ===  p[:id]
        @test_throws ArgumentError PNML.place(net, :bogus)
        PRINT_PNML && println("place $(PNML.id(p)) $(PNML.marking(p))")
    end
    for t in PNML.transitions(net)
        #printnode(t; label="transition")
        @test PNML.has_transition(net, t[:id])
        @test t == PNML.transition(net, t[:id])
        @test PNML.id(t) ===  t[:id]
        @test_throws ArgumentError PNML.transition(net, :bogus)
        PRINT_PNML && println("transition $(PNML.id(t)) $(PNML.condition(t))")
    end
    for a in PNML.arcs(net)
        #printnode(a, label="arc")
        @test PNML.has_arc(net, a[:id])
        @test a == PNML.arc(net, a[:id])
        @test PNML.id(a) ===  a[:id]
        @test_throws ArgumentError PNML.arc(net, :bogus)
        PRINT_PNML && println("arc $(PNML.id(a)) s:$(PNML.source(a)) t:$(PNML.target(a)) $(PNML.inscription(a))")
    end
    
    #dump(net)
end

@testset "Petri" begin
    str = """<?xml version="1.0"?>
    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
        <net id="net0" type="pnmlcore">
        <page id="page0">
            <place id="wolves">  <initialMarking> <text>10.0</text> </initialMarking> </place>
            <place id="rabbits"> <initialMarking> <text>100.0</text> </initialMarking> </place>
            <transition id ="birth">     <condition> <text>0.3</text> </condition> </transition>
            <transition id ="predation"> <condition> <text>0.015</text> </condition> </transition>
            <transition id ="death">     <condition> <text>0.7</text> </condition> </transition>
            <arc id="a1" source="rabbits"   target="birth"> <inscription><text>1</text> </inscription> </arc>
            <arc id="a2" source="birth"     target="rabbits"> <inscription><text>2</text> </inscription> </arc>
            <arc id="a3" source="wolves"    target="predation"> <inscription><text>1</text> </inscription> </arc>
            <arc id="a4" source="rabbits"   target="predation"> <inscription><text>1</text> </inscription> </arc>
            <arc id="a5" source="predation" target="wolves"> <inscription><text>2</text> </inscription> </arc>
            <arc id="a6" source="wolves"    target="death"> <inscription><text>1</text> </inscription> </arc>
        </page>
        </net>
    </pnml>
    """ 
 
    doc = PNML.Document(PNML.parse_doc(EzXML.parsexml(str)))
    net1 = PNML.first_net(doc)
    printnode(net1, label="Petri Net ")
    snet = PNML.SimpleNet(net1)
    
    S = PNML.place_ids(snet) # [:rabbits, :wolves]
    T = PNML.transition_ids(snet)
    @show S, T
    for t in T
        @show PNML.in_out(snet, t)
    end

    # keys are transition ids
    # values are input, output vectors of "tuples" place id -> inscription (integer?)
    Δ = PNML.transition_function(snet)#,T)
    tfun = LVector(
        birth=(LVector(rabbits=1), LVector(rabbits=2)),
        predation=(LVector(wolves=1, rabbits=1), LVector(wolves=2)),
        death=(LVector(wolves=1), LVector()),
    )
    @show Δ
    @show tfun
    @test Δ.birth     == tfun.birth
    @test Δ.predation == tfun.predation
    @test Δ.death     == tfun.death

    uX = LVector(wolves=10.0, rabbits=100.0) # initialMarking
    u0 = PNML.initialMarking(snet) #, S)
    @show u0
    @test u0 == uX
    βx = LVector(birth=.3, predation=.015, death=.7); # transition condition
    β = PNML.conditions(snet) #LVector( (; [t=>PNML.condition(snet,t) for t in T]...))
    @show β
    @test β == βx
end
