header("SimpleNet")

@testset "SIMPLENET" begin
    str = """
    <?xml version="1.0"?>
    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
        <net id="net0" type="continuous">
            <page id="page0">
            <place id="p1"> <initialMarking> <text>1.0</text> </initialMarking> </place>
            <place id="p2"> <initialMarking> <text>2.0</text> </initialMarking> </place>
            <place id="p3">
                <structure att1="doo"/>
                <frog name="hoppy" />
            </place>
            <transition id ="t1"> </transition>
            <transition id ="t2"> </transition>
            <transition id ="t3"> </transition>
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
    printnode(nets(model))

    v = PNML.find_nets(model, :continuous)
    @test v[begin] == PNML.first_net(model)
    @test first(v) == PNML.first_net(model)

    net  = PNML.SimpleNet(v[begin])
    net1 = PNML.SimpleNet(model)
    net2 = PNML.SimpleNet(PNML.first_net(model))

    for accessor in [pid, place_ids, transition_ids, arc_ids,
                     reftransition_ids, refplace_ids]
        @test accessor(net1) == accessor(net)
        @test accessor(net2) == accessor(net1)
        @test accessor(net2) == accessor(net)
    end

    for accessor in [places, transitions, arcs]
        for (a,b) in zip(accessor(net1), accessor(net))
            @test pid(a) == pid(b)
        end
        for (a,b) in zip(accessor(net2), accessor(net1))
            @test pid(a) == pid(b)
        end
        for (a,b) in zip(accessor(net2), accessor(net))
            @test pid(a) == pid(b)
        end
    end

    for top in [net, net.net, first(pages(net.net))]
        for p in places(top)
            @test has_place(top, pid(p))
            @test p == place(top, pid(p))
            @test pid(p) ===  p.id
            @test place(top, :bogus) === nothing
            @test typeof(marking(p)) <: typeof(default_marking(nettype(p))())
            @test marking(p) isa typeof(default_marking(nettype(p))())
        end
        for t in transitions(top)
            @test has_transition(top, pid(t))
            @test t == transition(top, pid(t))
            @test pid(t) ===  t.id
            @test transition(top, :bogus) === nothing
            @test condition(t) !== nothing
        end
        for a in arcs(top)
            @test has_arc(top, pid(a))
            @test a == arc(top, pid(a))
            @test pid(a) ===  a.id
            @test arc(net, :bogus) === nothing
            @test PNML.source(a) !== nothing
            @test PNML.target(a) !== nothing
            @test inscription(a) !== nothing
        end
    end
end

header("RATE")
@testset "rate" begin
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
    #printnode(net, label="rate net")

    snet = PNML.SimpleNet(net)
    @show snet
    β = PNML.rates(snet)
    @show β
    @test β == LVector(birth=0.3)
end

header("LOTKA-VOLTERRA")
@testset "lotka-volterra" begin
    str = """<?xml version="1.0"?>
    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
        <net id="net0" type="continuous">
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
    @test Δ.birth     == tfun.birth
    @test Δ.predation == tfun.predation
    @test Δ.death     == tfun.death

    uX = LVector(wolves=10.0, rabbits=100.0) # initialMarking
    u0 = PNML.initialMarking(snet)
    @test u0 == uX
    βx = LVector(birth=0.3, predation=0.015, death=0.7); # transition rate
    β = PNML.rates(snet)
    if PRINT_PNML
        @show Δ
        @show u0
        @show uX
        @show βx
        @show β
    end
    @test β == βx
end
