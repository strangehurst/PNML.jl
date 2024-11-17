using PNML, ..TestUtils, JET, LabelledArrays, AbstractTrees
using Test, Logging

testlogger = TestLogger()
println("SIMPLENET")
str1 = """
<?xml version="1.0"?>
    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
        <net id="net0" type="what">
            <page id="page0">
            <place id="p1"> <initialMarking> <text>1</text> </initialMarking> </place>
            <place id="p2"> <initialMarking> <text>2</text> </initialMarking> </place>
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

@testset "SIMPLENET" begin
    @test_call target_modules=target_modules parse_str(str1)
    # model = @test_logs(match_mode=:any,
    #     (:warn,"found unexpected label of <place>: structure"),
    #     (:warn,"found unexpected label of <place>: frog"),
    #     parse_str(str1))

    model = parse_str(str1)
    net0 = @inferred PnmlNet first(nets(model))
    snet1 = @inferred SimpleNet SimpleNet(model)
    snet  = @inferred SimpleNet SimpleNet(net0)
    #@show snet1

    @test_opt target_modules=(@__MODULE__,) SimpleNet(net0)
    @test_call broken=false SimpleNet(net0)

    @test_opt target_modules=(@__MODULE__,) SimpleNet(model)
    @test_call broken=false SimpleNet(model)

    for accessor in [pid,
                     place_idset, transition_idset, arc_idset,
                     reftransition_idset, refplace_idset]
        @test accessor(snet1) == accessor(snet)
    end

    @testset "inferred" begin
        # First @inferred failure throws exception ending testset.
        @test firstpage(snet.net) === first(pages(snet.net))

        #@inferred places(first(pages(net.net)))
        #@inferred transitions(first(pages(net.net)))
        #@inferred arcs(first(pages(net.net)))

        #@inferred places(net.net)
        #@inferred transitions(net.net)
        #@inferred arcs(net.net)

        @inferred Base.ValueIterator places(snet)
        @inferred Base.ValueIterator transitions(snet)
        @inferred Base.ValueIterator arcs(snet)
    end

    # page, pnmlnet, petrinet, the 3 top=levels
    #@show typeof(first(pages(snet.net))) typeof(snet.net) typeof(snet)
    @test first(pages(snet.net)) isa Page
    @test snet.net isa PnmlNet
    @test snet isa PNML.AbstractPetriNet

    for top in [first(pages(snet.net)), snet.net, snet]

        @test_call target_modules=target_modules places(top)
        for placeid in place_idset(top)
            has_place(top, placeid)
            @test_call has_place(top, placeid)
            @test @inferred has_place(top, placeid)
            p = @inferred Maybe{Place} place(top, placeid)
        end

        @test_call target_modules=target_modules transitions(top)
        for t in transitions(top)
            @test PNML.ispid(pid(t))(pid(t))
            @test_call has_transition(top, pid(t))
            @test @inferred Maybe{Bool} has_transition(top, pid(t))
            t == @inferred Maybe{Transition} transition(top, pid(t))
            @test pid(t) ===  t.id

            @test @inferred(condition(t)) !== nothing
        end

        @test_call target_modules=target_modules arcs(top)
        for a in arcs(top)
            @test @inferred Maybe{Bool} has_arc(top, pid(a))
            a == @inferred Maybe{Arc} arc(top, pid(a))
            @test pid(a) ===  a.id
                        @test @inferred(PNML.source(a)) !== nothing
            @test @inferred(PNML.target(a)) !== nothing
            @test @inferred(Number, inscription(a)) !== nothing
        end
    end

    # PetriNet-only methods.
    @testset "initialMarking" begin
        u1 = @inferred LArray initial_markings(snet)
        #!u2 = @inferred LArray initial_markings(snet.net)
        #!u3 = @inferred LArray initial_markings(first(pages(snet.net)))

        #@test u1 == u2
        #@test u1 == u3
        #@test typeof(u1) == typeof(u2)
        #@test typeof(u1) == typeof(u3)
    end
end

# Used in precompile.
@testset "simple ptnet" begin
    @show "precompile's SimpleNet"
    @test PNML.SimpleNet("""<?xml version="1.0"?>
        <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
        <net id="smallnet" type="http://www.pnml.org/version-2009/grammar/ptnet">
            <name> <text>P/T Net with one place</text> </name>
            <page id="page1">
            <place id="place1">
                <initialMarking> <text>100</text> </initialMarking>
            </place>
            <transition id="transition1">
                <name><text>Some transition</text></name>
            </transition>
            <arc source="transition1" target="place1" id="arc1">
                <inscription><text>12</text></inscription>
            </arc>
            </page>
        </net>
        </pnml>""") isa PNML.SimpleNet
end

@testset "rate" begin
    str2 = """<?xml version="1.0"?>
    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
        <net id="net0" type="core">
        <page id="page0">
            <transition id ="birth"><rate> <text>0.3</text> </rate> </transition>
        </page>
        </net>
    </pnml>
    """
    model = @inferred PNML.PnmlModel parse_str(str2)
    net = @inferred first(nets(model))
    snet = @inferred PNML.SimpleNet(net)
    @test contains(sprint(show, snet), "SimpleNet")
    β = PNML.rates(snet)
    #@show β
    @test β == LVector(birth=0.3)
end

@testset "lotka-volterra" begin
    str3 = """<?xml version="1.0"?>
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
    model = @test_logs(@inferred(PNML.PnmlModel, parse_str(str3)));
    net1 = first(nets(model));          #@show typeof(net1)
    snet = @inferred PNML.SimpleNet(net1); #@show typeof(snet)

    S = @inferred collect(PNML.place_idset(snet)) # [:rabbits, :wolves]
    T = @inferred collect(PNML.transition_idset(snet))
    @show PNML.input_matrix(snet)
    @show PNML.output_matrix(snet)
    @show PNML.conditions(snet)
    @show PNML.inscriptions(snet)
    println("all arcs = ", collect(PNML.all_arcs(snet, :wolves)))
    println("src arcs = ", collect(PNML.src_arcs(snet, :wolves)))
    println("tgt arcs = ", collect(PNML.tgt_arcs(snet, :wolves)))

    # keys are transition ids
    # values are input, output vectors of "tuples" place id -> inscription of arc
    Δ = PNML.transition_function(snet)#,T)
    @show S T Δ

    # Expected result
    expected_transition_function = LVector(
        birth=(LVector(rabbits=1.0), LVector(rabbits=2.0)),
        predation=(LVector(wolves=1.0, rabbits=1.0), LVector(wolves=2.0)),
        death=(LVector(wolves=1.0), LVector()),
    )

    @test typeof(Δ)   == typeof(expected_transition_function)
    @test Δ.birth     == expected_transition_function.birth
    @test Δ.predation == expected_transition_function.predation
    @test Δ.death     == expected_transition_function.death

    uX = LVector(wolves=10.0, rabbits=100.0) # initialMarking
    u0 = PNML.initial_markings(snet)
    @test u0 == uX

    βx = LVector(birth=0.3, predation=0.015, death=0.7); # transition rate
    β = PNML.rates(snet)
    @show β
    @test β == βx
end

using Graphs, MetaGraphsNext
using PNML: AbstractPetriNet, enabled

#println()
#println("=========="^12)
#println("=========="^12)
#println()
const core_types = ("pnmlcore","ptnet")
const hl_types = ("highlevelnet","hlnet","hlcore","pt_hlpng","symmetric")
const ex_types = ("continuous",)
nettype_strings() = tuple(core_types..., hl_types..., ex_types...)
#@show nettype_strings()

@testset "extract a graph $pntd" for pntd in nettype_strings()
    #println(); println("extract a graph $pntd"); println(); flush(stdout) #! debug
    if pntd in hl_types
        marking = """
        <hlinitialMarking>
            <text>1</text>
            <structure>
                <numberof>
                    <subterm><numberconstant value="1"><positive/></numberconstant></subterm>
                    <subterm><dotconstant/></subterm>
                </numberof>
            </structure>
        </hlinitialMarking>
        """
        insctag = "hlinscription"
    else
        marking = """
        <initialMarking>
            <text>1</text>
        </initialMarking>
        """
        insctag = "inscription"
    end
    #println()
    #println(marking)
    str3 = """<?xml version="1.0"?>
    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
        <net id="net0" type="$pntd">
        <name><text>test petri net</text></name>
        <page id="page0">
            <place id="p1"> $marking </place>
            <place id="p2"/>
            <place id="p3"/>
            <place id="p4"/>
            <place id="p0"/>
            <transition id="t1">
                <condition>
                    <text></text><structure><booleanconstant value="true"/></structure>
                </condition>
            </transition>
            <transition id="t2"/>
            <transition id="t3"/>
            <transition id="t4"/>
            <arc id="a1" source="p1"   target="t1"/>
            <arc id="a2" source="t1"   target="p2"/>
            <arc id="a3" source="p2"   target="t2"/>
            <arc id="a4" source="t2"   target="p3"/>
            <arc id="a5" source="p3"   target="t3"/>
            <arc id="a6" source="t3"   target="p4"/>
            <arc id="a7" source="p4"   target="t4"/>
            <arc id="a8" source="t4"   target="p1"/>

            <arc id="a9" source="t4"   target="p0"/>
        </page>
        </net>
    </pnml>
    """
    anet = PNML.SimpleNet(str3)::PNML.AbstractPetriNet
    #@show anet
    mg = PNML.metagraph(anet)

    println(); flush(stdout)
    @show C  = PNML.incidence_matrix(anet)
    @show m₀ = initial_markings(anet) #::LVector

    @error "muladd(C', [1,0,0,0], m₀) is BROKEN !!!"
    #@show muladd(C', [1,0,0,0], m₀)

    @error "PNML.enabled(anet, m₀) is BROKEN !!!"
    # @show e  = PNML.enabled(anet, m₀) #::LVector
    # @test values(e) == [true,false,false,false]
    # @test e == [true,false,false,false]
    # @test e == Bool[1,0,0,0]
    # @test e == [1,0,0,0]

    # m₁ = PNML.fire!(C, e, m₀)

    #@test values(enabled(anet, m₁)) == [false,true,false,false]
#=
    @show m₂ =  muladd(C', [0,1,0,0], m₁) typeof(m₂)
    #@test enabled(anet, m₂) == [false,false,true,false]

    @show m₃ =  muladd(C', [0,0,1,0], m₂) typeof(m₃)
    #@test enabled(anet, m₃) == [false,false,false,true]

    @show m₄ =  muladd(C', [0,0,0,1], m₃)
    #@test enabled(anet, m₄) == [true,false,false,false]

    @show m₅ =  muladd(C', [1,0,0,0], m₄)
    #@test enabled(anet, m₅) == [false,true,false,false]
    @show m₆ =  muladd(C', [0,1,0,0], m₅)
    #@test enabled(anet, m₆) == [false,false,true,false]
    @show m₇ =  muladd(C', [0,0,1,0], m₆)
    #@test enabled(anet, m₇) == [false,false,false,true]
    @show m₈ =  muladd(C', [0,0,0,1], m₇)
    #@test enabled(anet, m₈) == [true,false,false,false]
    @show m₉ =  muladd(C', [1,0,0,0], m₈)
    #@test enabled(anet, m₉) == [false,false,false,true]
=#
end
