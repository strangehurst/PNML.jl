
@testset "deref" begin
    str = """
    <?xml version="1.0"?>
    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
        <net id="net0" type="pnmlcore">
            <page id="page1">
                <place id="p1"/>
                <transition id ="t1"/>
                <arc id="a1" source="p1" target="t1"/>
                <arc id="a12" source="t1" target="rp1"/>
                <referencePlace id="rp1" ref="p2"/>
            </page>
            <page id="page2">
                <place id="p2"/>
                <transition id ="t2"/>
                <arc id="a2" source="t2" target="p2"/>
                <arc id="a22" source="t2" target="rp2"/>
                <referencePlace id="rp2" ref="p3"/>
                <referenceTransition id="rt2" ref="t3"/>
            </page>
            <page id="page3">
                <place id="p3"/>
                <transition id ="t3"/>
                <arc id="a3" source="t3" target="p3"/>
            </page>
        </net>
    </pnml>
        """ 
    doc = PNML.Document(str)

    PRINT_PNML && println(
    """------------------------------------------------------------
    EXPANDED
    ------------------------------------------------------------""")
    net = PNML.first_net(doc)
    printnode(net; compress=false)

    PRINT_PNML && println(
    """------------------------------------------------------------
    FLATTENED
    ------------------------------------------------------------""")
    PNML.flatten_pages!(net)
    printnode(net; compress=false)

    PRINT_PNML && println(
    """------------------------------------------------------------
    COMPRESSED
    ------------------------------------------------------------""")
    @test net isa PNML.PnmlDict
    cnet = PNML.compress(net)
    @test cnet isa PNML.PnmlDict
    printnode(cnet)
    @test cnet != net

    PRINT_PNML && println(
    """------------------------------------------------------------
    DEREFERENCED
    ------------------------------------------------------------""")
    
    snet = PNML.SimpleNet(cnet)

    PRINT_PNML && println("from")
    PRINT_PNML && @show snet

    PNML.deref!(snet)
    @test snet != cnet

    PRINT_PNML && println("to")
    PRINT_PNML && @show snet
    PRINT_PNML && println("------------------------------------------------------------")
end

@testset "net type" begin
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
    
    reg = PNML.IDRegistry()
    doc = PNML.Document(str, reg)
    printnode(doc.nets, label="net type")
    
    v = PNML.find_nets(doc, :pnmlcore)
    @test !isempty(v)
    @test v[begin] == PNML.first_net(doc)

    net  = PNML.SimpleNet(v[begin])
    net1 = PNML.SimpleNet(doc)
    net2 = PNML.SimpleNet(PNML.first_net(doc))
    PRINT_PNML && println()
    PRINT_PNML && @show net
    PRINT_PNML && println()
    #TODO why do the 3 top-level nets compare not equal?
    for accessor in [PNML.id, PNML.places, PNML.transitions, PNML.arcs,
                     PNML.place_ids, PNML.transition_ids, PNML.arc_ids]
        @test accessor(net1) == accessor(net)
        @test accessor(net2) == accessor(net)
        @test accessor(net2) == accessor(net1)
    end
    
    PRINT_PNML && println("""------------------------------------------
    compress
    """)
    pl = PNML.places(net)
    printnode(pl[1], compress=false)
    cpn = PNML.compress(pl[1])
    PRINT_PNML && println("to")
    printnode(cpn, compress=false) #
    PRINT_PNML && println()
    printnode(cpn, compress=true) # 
    PRINT_PNML && println("from")
    printnode(pl[1], compress=false)
    PRINT_PNML && println("------------------------------------------")
    PRINT_PNML && println()
    PRINT_PNML && println("------------------------------------------")
    PRINT_PNML && println("compress")
    pl = PNML.places(net)
    printnode(pl, compress=false)
    cpl = PNML.compress(pl)
    PRINT_PNML && println("to")
    printnode(cpl, compress=false)
    @test pl != cpl
    PRINT_PNML && println("------------------------------------------")
    PRINT_PNML && println()

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
    end

@testset "lotka-volterra" begin
    str = """<?xml version="1.0"?>
    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
        <net id="net0" type="stochastic">
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
    #@test !PNML.isregistered(:pnml)
    reg = PNML.IDRegistry()
    doc = PNML.Document(str, reg)
    net1 = PNML.first_net(doc)
    printnode(net1, label="Petri Net ")
    snet = PNML.SimpleNet(net1)
    
    S = PNML.place_ids(snet) # [:rabbits, :wolves]
    T = PNML.transition_ids(snet)
    PRINT_PNML && @show S, T
    for t in T
        PRINT_PNML && @show PNML.in_out(snet, t)
    end

    # keys are transition ids
    # values are input, output vectors of "tuples" place id -> inscription (integer?)
    Δ = PNML.transition_function(snet)#,T)
    tfun = LVector(
        birth=(LVector(rabbits=1), LVector(rabbits=2)),
        predation=(LVector(wolves=1, rabbits=1), LVector(wolves=2)),
        death=(LVector(wolves=1), LVector()),
    )
    PRINT_PNML && @show Δ
    PRINT_PNML && @show tfun
    @test Δ.birth     == tfun.birth
    @test Δ.predation == tfun.predation
    @test Δ.death     == tfun.death

    uX = LVector(wolves=10.0, rabbits=100.0) # initialMarking
    u0 = PNML.initialMarking(snet) #, S)
    PRINT_PNML && @show u0
    @test u0 == uX
    βx = LVector(birth=.3, predation=.015, death=.7); # transition condition
    β = PNML.conditions(snet) #LVector( (; [t=>PNML.condition(snet,t) for t in T]...))
    PRINT_PNML && @show β
    @test β == βx
end
