using PNML, EzXML, ..TestUtils, JET, XMLDict

@testset "place $pntd" for pntd in all_nettypes(!ishighlevel)
    node = xml"""
        <place id="place1">
        <name> <text>with text</text> </name>
        <initialMarking> <text>100</text> </initialMarking>
        </place>
    """
    n  = parse_place((:NN,), node, pntd, registry())
    @test_opt target_modules=(@__MODULE__,) parse_place((:NN,), node, pntd, registry())
    @test_call target_modules=target_modules parse_place((:NN,), node, pntd, registry())
    @test isa(n, Place)
    @test @inferred(pid(n)) === :place1
    @test has_name(n)
    @test @inferred(name(n)) == "with text"
    @test_call initial_marking(n)
    @test @inferred(initial_marking(n)()) == 100
end

@testset "place $pntd" for pntd in all_nettypes(ishighlevel)
    node = xml"""
        <place id="place1">
        <name> <text>with text</text> </name>
        <hlinitialMarking> <text>100</text> </hlinitialMarking>
        </place>
    """
    n  = parse_place((:NN,), node, pntd, registry())
    @test_call target_modules=target_modules parse_place((:NN,), node, pntd, registry())

    @test pid(n) === :place1
    @test typeof(n) <: Place
    @test @inferred(pid(n)) === :place1
    @test has_name(n)
    @test @inferred(name(n)) == "with text"
    @test_call target_modules=(@__MODULE__,) initial_marking(n)
    @test initial_marking(n)() ==  zero(PNML.marking_value_type(pntd)) # text has no meaning here
end

@testset "transition $pntd" for pntd in all_nettypes()
    node = xml"""
      <transition id="transition1">
        <name> <text>Some transition</text> </name>
        <condition> <text>always true</text>
                    <structure> <booleanconstant value="true"/></structure>
        </condition>
      </transition>
    """
    n = @inferred Transition parse_transition((:NN,), node, PnmlCoreNet(), registry())
    @test typeof(n) <: Transition
    @test pid(n) === :transition1
    @test has_name(n)
    @test name(n) == "Some transition"
    @test condition(n) isa Bool

    node = xml"""<transition id ="t1"> <condition><text>test</text></condition></transition>"""
    #@test_throws ErrorException parse_transition(node, pntd, registry())
    @test @test_logs(parse_transition((:NN,), node, pntd, registry())) !== nothing

    node = xml"""<transition id ="t2"> <condition/> </transition>"""
    @test @test_logs(parse_transition((:NN,), node, pntd, registry())) isa Transition

    node = xml"""<transition id ="t3"> <condition><structure/></condition> </transition>"""
    @test_throws "ArgumentError: missing condition term element in <structure>" parse_transition((:NN,), node, pntd, registry())

    node = xml"""<transition id ="t4">
        <condition>
           <text>test true</text>
            <structure> true  </structure>
        </condition>
    </transition>"""
    @test_throws "missing condition term element in <structure>" parse_transition((:NN,), node, pntd, registry())
    # t = @test_logs((:warn, "replacing empty <structure> content value for condition term with: true"),
    # parse_transition(node, pntd, registry()))
    # @test_opt target_modules=(@__MODULE__,) condition(t)
    # @test_call condition(t)
    # @test condition(t) === true

    node = xml"""<transition id ="t5">
        <condition>
            <text>test true</text>
            <structure> <booleanconstant value="true"/> </structure>
        </condition>
    </transition>"""
    t = parse_transition((:NN,), node, pntd, registry())
    @test t isa Transition
    @test condition(t) === true

    # From [Tina .pnml formt](file://~/PetriNet/tina-3.7.5/doc/html/formats.html#5)
    # This bit may be from the pre-standard era.
    # <ci> is a variable(constant) like pi, infinity.
    # <cn> is a number (real)
    # interval [4,9]
    node = xml"""<transition id ="t6">
        <delay>
            <interval xmlns="http://www.w3.org/1998/Math/MathML" closure="closed">
                <cn>4</cn>
                <cn>9</cn>
            </interval>
         </delay>
    </transition>"""
    t = parse_transition((:NN,), node, pntd, registry())
    @test t isa Transition
    @test PNML.delay(t) isa Tuple

    # unbounded interval [4,∞)
    node = xml"""<transition id ="t7">
        <delay>
            <interval xmlns="http://www.w3.org/1998/Math/MathML" closure="closed-open">
                <cn>4</cn>
                <ci>infty</ci>
            </interval>
        </delay>
    </transition>"""
    t = parse_transition((:NN,), node, pntd, registry())
    @test t isa Transition
    @test PNML.delay(t) isa Tuple

    # interval (3,5)
    node = xml"""<transition id ="t8">
        <delay>
            <interval xmlns="http://www.w3.org/1998/Math/MathML" closure="open">
                <cn>3</cn>
                <cn>5</cn>
            </interval>
        </delay>
    </transition>"""
    t = parse_transition((:NN,), node, pntd, registry())
    @test t isa Transition
    @test PNML.delay(t) isa Tuple
end

@testset "arc $pntd"  for pntd in all_nettypes()
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
    PNML.CONFIG.warn_on_unclaimed = true
    if ishighlevel(pntd)
        @test_throws "missing inscription term element in <structure>" parse_arc((:NN,), node, pntd, registry())
    else
        a1 = @test_logs(match_mode=:any,
                (:warn, "found unexpected child of <arc>: unknown"),
                parse_arc((:NN,), node, pntd, registry()))
        a2 = Arc(a1, Ref(:newsrc), Ref(:newtarget))
        @testset "a1,a2" for a in [a1, a2]
            @test typeof(a) <: Arc
            @test pid(a) === :arc1
            @test has_name(a)
            @test name(a) == "Some arc"
            @test_call  inscription(a)
            @test inscription(a) == 6
        end
    end
end

@testset "ref Trans $pntd" for pntd in all_nettypes()
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
    n = @test_logs (:warn, "found unexpected child of <referenceTransition>: unknown") parse_refTransition((:NN,), node, pntd, registry())
    @test n isa RefTransition
    @test pid(n) === :rt1
    @test refid(n) === :t1
    @test PNML.has_graphics(n) && startswith(repr(PNML.graphics(n)), "Graphics")
end

@testset "ref Place $pntd" for pntd in all_nettypes()
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
    </referencePlace>""", id="rp2", ref="rp1" )

    n2 = (node = xml"""
    <referencePlace id="rp1" ref="Sync1">
        <graphics>
          <position x="734.5" y="41.5"/>
          <dimension x="40.0" y="40.0"/>
        </graphics>
        <unknown id="unkn"/>
    </referencePlace>""", id="rp1", ref="Sync1")

    @testset "referencePlaces" for s in [n1, n2]
        n = @test_logs(match_mode=:any,
            (:warn, "found unexpected child of <referencePlace>: unknown"),
            parse_refPlace((:NN,), s.node, ContinuousNet(), registry()))
        @test typeof(n) <: RefPlace
        @test pid(n) === Symbol(s.id)
        @test refid(n) === Symbol(s.ref)
    end
end
