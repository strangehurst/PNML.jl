using PNML, EzXML, ..TestUtils, JET, LabelledArrays, AbstractTrees
using PNML: tag, pid, xmlnode, parse_str,
    Maybe, SimpleNet, PnmlNet, Place, Transition, Arc,
    nets, pages,
    place, places, has_place,
    transition, transitions, has_transition,
    arc, arcs, has_arc,
    place_ids, transition_ids, arc_ids, refplace_ids, reftransition_ids,
    marking, default_marking,  currentMarkings,
    condition, default_condition,
    inscription, default_inscription,
    nettype, firstpage,
    ispid

using Test, Logging
testlogger = TestLogger()

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
    @test_call target_modules=target_modules parse_str(str)
    model = @inferred parse_str(str)

    @test_call PNML.find_nets(model, :continuous)
    v = @inferred PNML.find_nets(model, :continuous)

    @test_call PNML.first_net(model)
    @test v[begin] == @inferred PnmlNet PNML.first_net(model)
    @test first(v) == @inferred PnmlNet PNML.first_net(model)

    @test_call SimpleNet(v[begin])
    @test_call SimpleNet(model)
    @test_call SimpleNet(PNML.first_net(model))

    net  = @inferred SimpleNet SimpleNet(v[begin])
    net1 = @inferred SimpleNet SimpleNet(model)
    net2 = @inferred SimpleNet SimpleNet(PNML.first_net(model))

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

    @testset "inferred" begin
        #println()
        #@show "start inferred"
        # First @inferred failure throws exception ending testset.
        @test firstpage(net.net) === first(pages(net.net))
        #@show typeof(firstpage(net.net))
        @inferred places(first(pages(net.net)))
        @inferred transitions(first(pages(net.net)))
        @inferred arcs(first(pages(net.net)))

        #@show typeof(net.net)
        @inferred places(net.net)
        @inferred transitions(net.net)
        @inferred arcs(net.net)

        #@show typeof(net)
        @inferred places(net)
        @inferred transitions(net)
        @inferred arcs(net)
    end

    for top in [first(pages(net.net)), net.net, net]
        #println()
        #@show typeof(top)
        #@show length(pages(top))
        @test_call target_modules=target_modules places(top)
        #=
        for x in AbstractTrees.PreOrderDFS(top)
            println(pid(x), " ", length(pages(x)))
            println(place_ids(x), " ",
                    transition_ids(x), " ",
                    arc_ids(x), " ",
                    refplace_ids(x), " ",
                    reftransition_ids(x))
        end
        =#
        for p in places(top)
            #@show "place $(pid(p))"

            @test_call has_place(top, pid(p))
            @test @inferred has_place(top, pid(p))
            p == @inferred Maybe{Place} place(top, pid(p))
            @test pid(p) ===  p.id
            @test @inferred(Maybe{Place}, place(top, :bogus)) === nothing
            @test typeof(marking(p)) <: typeof(default_marking(p))
            @test @inferred(marking(p)) isa typeof(default_marking(p))
        end
        #println()
    end

    for top in [net, net.net, first(pages(net.net))]
        @test_call target_modules=target_modules transitions(top)
        for t in transitions(top)
            #@show "transition $(pid(t))"
            @test PnmlCore.ispid(pid(t))(pid(t))
            @test_call has_transition(top, pid(t))
            @test @inferred Maybe{Bool} has_transition(top, pid(t))
            t == @inferred Maybe{Transition} transition(top, pid(t))
            @test pid(t) ===  t.id
            @test transition(top, :bogus) === nothing
            @test condition(t) !== nothing
            @test @inferred condition(t)
        end
    end

    #
    for top in [net, net.net, first(pages(net.net))]
        @test_call target_modules=target_modules arcs(top)
        for a in arcs(top)
            #@show "arc $(pid(a))"
            #@show a
            #@show pid(a), inscription(a), typeof(inscription(a)), default_inscription(a)
            #@show has_arc(top, pid(a))
            #@show typeof(has_arc(top, pid(a)))
            @test @inferred Maybe{Bool} has_arc(top, pid(a))
            a == @inferred Maybe{Arc} arc(top, pid(a))
            @test pid(a) ===  a.id
            @test arc(net, :bogus) === nothing
            @test @inferred(PNML.source(a)) !== nothing
            @test @inferred(PNML.target(a)) !== nothing
            @test @inferred(inscription(a)) !== nothing
        end
    end
    @testset "initialMarking" begin
        u1 = @inferred LArray currentMarkings(net)
        u2 = @inferred LArray currentMarkings(net.net)
        u3 = @inferred LArray currentMarkings(first(pages(net.net)))
        #@show typeof(net)
        #@show typeof(net.net)
        #@show typeof(firstpage(net.net))
        #@show typeof(currentMarkings(net))
        #@show typeof(currentMarkings(net.net))
        #@show typeof(currentMarkings(firstpage(net.net)))
        @test u1 == u2
        @test u1 == u3
        @test typeof(u1) == typeof(u2)
        @test typeof(u1) == typeof(u3)
    end
end

@testset "rate" begin
    str = """<?xml version="1.0"?>
    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
        <net id="net0" type="core">
        <page id="page0">
            <transition id ="birth"><rate> <text>0.3</text> </rate> </transition>
        </page>
        </net>
    </pnml>
    """
    model = @inferred parse_str(str)
    net = PNML.first_net(model)
    @test net isa PnmlCore.PnmlNet
    snet = @inferred PNML.SimpleNet(net)
    #@show snet
    β = PNML.rates(snet)
    #@show β
    @test β == LVector(birth=0.3)
end

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
            <arc id="a1" source="rabbits"   target="birth"> <inscription><text>1.0</text> </inscription> </arc>
            <arc id="a2" source="birth"     target="rabbits"> <inscription><text>2.0</text> </inscription> </arc>
            <arc id="a3" source="wolves"    target="predation"> <inscription><text>1.0</text> </inscription> </arc>
            <arc id="a4" source="rabbits"   target="predation"> <inscription><text>1.0</text> </inscription> </arc>
            <arc id="a5" source="predation" target="wolves"> <inscription><text>2.0</text> </inscription> </arc>
            <arc id="a6" source="wolves"    target="death"> <inscription><text>1.0</text> </inscription> </arc>
        </page>
        </net>
    </pnml>
    """
    model = @inferred parse_str(str)
    net1 = PNML.first_net(model)

    snet = @inferred PNML.SimpleNet(net1)

    S = @inferred PNML.place_ids(snet) # [:rabbits, :wolves]
    T = @inferred PNML.transition_ids(snet)
    #!@show S, T
    #!for t in T
    #!@show PNML.in_out(snet, t)
    #!end

    # keys are transition ids
    # values are input, output vectors of "tuples" place id -> inscription (integer?)
    Δ = PNML.transition_function(snet)#,T)
    tfun = LVector(
        birth=(LVector(rabbits=1.0), LVector(rabbits=2.0)),
        predation=(LVector(wolves=1.0, rabbits=1.0), LVector(wolves=2.0)),
        death=(LVector(wolves=1.0), LVector()),
    )
    #!@show Δ.birth
    #!@show tfun.birth
    @test typeof(Δ)   == typeof(tfun)
    @test Δ.birth     == tfun.birth
    @test Δ.predation == tfun.predation
    @test Δ.death     == tfun.death

    uX = LVector(wolves=10.0, rabbits=100.0) # initialMarking
    u0 = PNML.currentMarkings(snet)
    @test u0 == uX

    βx = LVector(birth=0.3, predation=0.015, death=0.7); # transition rate
    β = PNML.rates(snet)
    #!@show Δ
    #!@show u0
    #!@show uX
    #!@show βx
    #!@show β

    @test β == βx
end
