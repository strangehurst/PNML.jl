header("SimpleNet")

@testset "SIMPLENET" begin
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
            <!-- missing structure is non-standard for SOME PNTDs -->
            <transition id ="t1"> <condition><text>true</text></condition> </transition>
            <!-- empty condition is malformed  -->
            <transition id ="t2"> <condition/> </transition>
            <!-- ommitted text  -->
            <transition id ="t3"> <condition><structure/></condition> </transition>
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

    model = parse_str(str)
    printnode(nets(model), label="SimpleNet")

    v = PNML.find_nets(model, :pnmlcore)
    @test !isempty(v)
    @test v[begin] == PNML.first_net(model)

    net  = PNML.SimpleNet(v[begin])
    net1 = PNML.SimpleNet(model)
    net2 = PNML.SimpleNet(PNML.first_net(model))

    PRINT_PNML && println()
    PRINT_PNML && @show net
    PRINT_PNML && println()

    for accessor in [PNML.pid, PNML.place_ids, PNML.transition_ids, PNML.arc_ids]
        @show accessor
        @test accessor(net1) == accessor(net)
        @test accessor(net2) == accessor(net1)
        @test accessor(net2) == accessor(net)
    end

    for accessor in [PNML.places, PNML.transitions, PNML.arcs]
        @show accessor
        for (a,b) in zip(accessor(net1), accessor(net))
            @test a.id == b.id
        end
        for (a,b) in zip(accessor(net2), accessor(net1))
            @test a.id == b.id
        end
        for (a,b) in zip(accessor(net2), accessor(net))
            @test a.id == b.id
        end

    end

    pl = PNML.places(net)
    printnode(pl[1],label="from")

    pl = PNML.places(net)
    printnode(pl, label="places")

    for p in PNML.places(net)
        @test PNML.has_place(net, pid(p))
        @test p == PNML.place(net, pid(p))
        @test PNML.pid(p) ===  p.id
        @test PNML.place(net, :bogus) === nothing
        PRINT_PNML && println("place $(PNML.pid(p)) $(PNML.marking(p))")
    end
    for t in PNML.transitions(net)
        @test PNML.has_transition(net, pid(t))
        @test t == PNML.transition(net, pid(t))
        @test PNML.pid(t) ===  t.id
        @test PNML.transition(net, :bogus) === nothing
        PRINT_PNML && println("transition $(PNML.pid(t)) $(PNML.condition(t))")
    end
    for a in PNML.arcs(net)
        @test PNML.has_arc(net, pid(a))
        @test a == PNML.arc(net, pid(a))
        @test PNML.pid(a) ===  a.id
        @test PNML.arc(net, :bogus) === nothing
        PRINT_PNML && println("arc $(PNML.pid(a)) s:$(PNML.source(a)) t:$(PNML.target(a)) $(PNML.inscription(a))")
    end
end


@testset "rate" begin
    header("RATE")
    str = """<?xml version="1.0"?>
    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
        <net id="net0" type="stochastic">
        <page id="page0">
            <transition id ="birth"><rate> <text>0.3</text> </rate> </transition>
        </page>
        </net>
    </pnml>
    """
    model = parse_str(str)
    net = PNML.first_net(model)
    printnode(net, label="rate net")

    snet = PNML.SimpleNet(net)
    @show snet
    β = PNML.rates(snet)
    @show β
    @test β == LVector(birth=.3);
end

@testset "lotka-volterra" begin
    header("LOTKA-VOLTERRA")
    str = """<?xml version="1.0"?>
    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
        <net id="net0" type="stochastic">
        <page id="page0">
            <place id="wolves">  <initialMarking> <text>10.0</text> </initialMarking> </place>
            <place id="rabbits"> <initialMarking> <text>100.0</text> </initialMarking> </place>
            <transition id ="birth">     <rate> <text>0.3</text> </rate> </transition>
            <transition id ="predation"> <rate> <text>0.015</text> </rate> </transition>
            <transition id ="death">     <rate> <text>0.7</text> </rate> </transition>
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
    model = parse_str(str)
    net1 = PNML.first_net(model)
    printnode(net1)
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
    βx = LVector(birth=.3, predation=.015, death=.7); # transition rate
    β = PNML.rates(snet) #LVector( (; [t=>PNML.rate(snet,t) for t in T]...))
    PRINT_PNML && @show β
    @test β == βx
end

@testset "merge pages" begin
    d1 = Dict(:id => :top,
              :pages => Dict[Dict(:id=>:p1, :arc => [Dict(:id=>:arc1)],),
                             Dict(:id=>:p2, :arc => [Dict(:id=>:arc2)],),
                             Dict(:id=>:p3, :arc => [Dict(:id=>:arc3)], :pages=>[]),
                             ],
              :arc => [Dict(:id=>:arc2)],)

end
