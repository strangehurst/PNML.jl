using PNML, EzXML, ..TestUtils, JET
using PNML: Place, Transition, Arc, RefPlace, RefTransition,
    has_xml, has_name, name,
    pid, marking, condition, inscription,
    has_graphics, graphics, has_name, name, has_label,
    parse_place, parse_transition, parse_arc, parse_refTransition, parse_refPlace

    @testset "place $pntd" for pntd in Iterators.filter(!PNML.ishighlevel, PNML.all_nettypes())
        node = xml"""
          <place id="place1">
            <name> <text>with text</text> </name>
            <initialMarking> <text>100</text> </initialMarking>
          </place>
        """
        n  = parse_place(node, pntd, registry())
        #println("parse_place "); dump(n)
        Base.redirect_stdio(stdout=testshow, stderr=testshow) do
            @show n PNML.default_marking(n) PNML.nettype(n) PNML.common(n)
        end

        nothing === @test_logs (:warn, r"^Attempt to parse excluded tag") parse_node(node, pntd, registry())

        @test_call target_modules=target_modules parse_place(node, pntd, registry())

        @test pid(n) === :place1
        @test typeof(n) <: Place
        @test_call has_xml(n)
        @test !has_xml(n)
        @test @inferred(pid(n)) === :place1
        @test has_name(n)
        @test @inferred(name(n)) == "with text"
        @test_call marking(n)
        @test marking(n)() == 100
    end

    @testset "place $pntd" for pntd in Iterators.filter(PNML.ishighlevel, PNML.all_nettypes())
        node = xml"""
          <place id="place1">
            <name> <text>with text</text> </name>
            <hlinitialMarking> <text>100</text> </hlinitialMarking>
          </place>
        """
        n  = parse_place(node, pntd, registry())
        #println("parse_place "); dump(n)
        Base.redirect_stdio(stdout=testshow, stderr=testshow) do
            @show n PNML.default_marking(n) PNML.nettype(n) PNML.common(n)
        end

        nothing === @test_logs (:warn, r"^Attempt to parse excluded tag") parse_node(node, pntd, registry())

        @test_call target_modules=target_modules parse_place(node, pntd, registry())

        @test pid(n) === :place1
        @test typeof(n) <: Place
        @test_call has_xml(n)
        @test !has_xml(n)
        @test @inferred(pid(n)) === :place1
        @test has_name(n)
        @test @inferred(name(n)) == "with text"
        @test_call marking(n)
        @test marking(n)() ==  zero(PNML.marking_value_type(pntd)) # text has no meaning here
    end

    # <condition> introduced as High-Level in specification. We use it everywhere.
@testset "transition $pntd" for pntd in PNML.all_nettypes()
    node = xml"""
      <transition id="transition1">
        <name> <text>Some transition</text> </name>
        <condition> <text>always true</text>
                    <structure> <booleanconstant value="true"/></structure>
        </condition>
      </transition>
    """
    n = @inferred Transition parse_transition(node, PnmlCoreNet(), registry())
    @test typeof(n) <: Transition
    @test !has_xml(n)
    @test pid(n) === :transition1
    @test has_name(n)
    @test name(n) == "Some transition"
    Base.redirect_stdio(stdout=testshow, stderr=testshow) do
        @show n PNML.default_condition(n) PNML.nettype(n) PNML.common(n.condition)
    end
    #println(pid(n)); dump(n)
    @test condition(n) isa Bool

    node = xml"""<transition id ="t1"> <condition><text>test</text></condition></transition>"""
    #@test_throws ErrorException parse_transition(node, pntd, registry())
    @test parse_transition(node, pntd, registry()) !== nothing
    node = xml"""<transition id ="t2"> <condition/> </transition>"""
    @test parse_transition(node, pntd, registry()) isa Transition

    node = xml"""<transition id ="t3"> <condition><structure/></condition> </transition>"""
    @test_throws ErrorException parse_transition(node, pntd, registry())
    #t = parse_transition(node, pntd, registry())
    #@test t isa Transition
    #@test_call condition(t)
    #@test condition(t) === true
end

@testset "arc $pntd"  for pntd in PNML.all_nettypes()
    insc_xml = if ishighlevel(pntd)
        """<hlinscription>
            <text>6</text>
            <structure> 6 </structure>
           </hlinscription>"""
    else
        """<inscription> <text>6</text> </inscription>"""
    end

    node = xmlroot("""
      <arc source="transition1" target="place1" id="arc1">
        <name> <text>Some arc</text> </name>
        $insc_xml
        <unknown id="unkn">
            <name> <text>unknown label</text> </name>
            <text>content text</text>
        </unknown>
      </arc>
    """)
    #a1 = @test_logs match_mode=:any (:warn, "inscription term <structure> content value: 6") (:warn, "unexpected child of <arc>: unknown")
    a1 = @test_logs match_mode=:any (:warn, "unexpected child of <arc>: unknown")
    a1 = parse_arc(node, pntd, registry())

    Base.redirect_stdio(stdout=testshow, stderr=testshow) do
        @show a1 PNML.default_inscription(a1) PNML.nettype(a1) PNML.common(a1)
    end
    #println("arc a1 $pntd:"); dump(a1)
    a2 = Arc(a1, :newsrc, :newtarget)
    #println("arc a2 with updated src, tgt:"); dump(a2)
    @testset "a1,a2" for a in [a1, a2]
        @test typeof(a) <: Arc
        @test !has_xml(a)
        @test pid(a) === :arc1
        @test has_name(a)
        @test name(a) == "Some arc"
        #@show inscription(a)
        @test_call  inscription(a)
        @test inscription(a) == 6
    end

end

@testset "ref Trans $pntd" for pntd in PNML.all_nettypes() #a" begin
    node = xml"""
        <referenceTransition id="rt1" ref="t1">
        <name> <text>refTrans name</text> </name>
        <graphics><offset x="0" y="0"/></graphics>
        <toolspecific tool="unknowntool" version="1.0"><atool x="0"/></toolspecific>
        <unknown id="unkn">
            <name> <text>unknown label</text> </name>
            <text>content text</text>
        </unknown>
    </referenceTransition>
    """
    n = @test_logs (:warn, "unexpected child of <referenceTransition>: unknown") parse_refTransition(node, pntd, registry())
    Base.redirect_stdio(stdout=testshow, stderr=testshow) do
        @show n PNML.common(n)
    end
   @test n isa RefTransition
    @test !has_xml(n)
    @test pid(n) === :rt1
    @test n.ref === :t1
end

@testset "ref Place $pntd" for pntd in PNML.all_nettypes() #a" begin" begin
    n1 = (node = xml"""
    <referencePlace id="rp2" ref="rp1">
        <name>
            <text>refPlace name</text>
            <unknown id="unkn">
                <name> <text>unknown label</text> </name>
                <text>content text</text>
            </unknown>
        </name>
        <graphics><offset x="0" y="0"/></graphics>
        <toolspecific tool="unknowntool" version="1.0"><atool x="0"/></toolspecific>
        <unknown id="unkn">
            <name> <text>unknown label</text> </name>
            <text>content text</text>
        </unknown>
    </referencePlace>""",
    id="rp2", ref="rp1" )
    n2 = (node = xml"""
    <referencePlace id="rp1" ref="Sync1">
        <graphics>
          <position x="734.5" y="41.5"/>
          <dimension x="40.0" y="40.0"/>
        </graphics>
        <unknown id="unkn"/>
    </referencePlace>""",
    id="rp1", ref="Sync1")
    @testset for s in [n1, n2]
        n = @test_logs (:warn, "unexpected child of <referencePlace>: unknown") match_mode=:any parse_refPlace(s.node, ContinuousNet(), registry())
        Base.redirect_stdio(stdout=testshow, stderr=testshow) do
            @show n PNML.common(n)
        end
           @test typeof(n) <: RefPlace
        @test !has_xml(n)
        @test typeof(n.id) == Symbol
        @test typeof(n.ref) == Symbol
        @test n.id === Symbol(s.id)
        @test n.ref === Symbol(s.ref)
    end
end
