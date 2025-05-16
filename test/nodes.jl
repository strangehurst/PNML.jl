using PNML, ..TestUtils, JET, XMLDict

@testset "place $pntd" for pntd in PnmlTypeDefs.all_nettypes(!ishighlevel)
    node = xml"""
        <place id="place1">
        <name> <text>with text</text> </name>
        <initialMarking> <text>100</text> </initialMarking>
        </place>
    """
    @with PNML.idregistry => PnmlIDRegistry() PNML.DECLDICT => PNML.DeclDict() begin
        PNML.fill_nonhl!(PNML.DECLDICT[])
        placetype = SortType("XXX", UserSort(:integer))

        n  = parse_place(node, pntd)::Place
        @test_opt target_modules=(@__MODULE__,) parse_place(node, pntd)
        @test_call target_modules=target_modules parse_place(node, pntd)
        @test @inferred(pid(n)) === :place1
        @test has_name(n)
        @test @inferred(name(n)) == "with text"
        @test_call initial_marking(n)
        @test initial_marking(n) == 100
    end
end

@testset "place $pntd" for pntd in PnmlTypeDefs.all_nettypes(ishighlevel)
    node = xml"""
        <place id="place1">
        <name> <text>with text</text> </name>
        <hlinitialMarking> <text>100</text> </hlinitialMarking>
        </place>
    """
    @with PNML.idregistry => PnmlIDRegistry() PNML.DECLDICT => DeclDict() begin
        PNML.fill_nonhl!(PNML.DECLDICT[])
        n  = parse_place(node, pntd)::Place
        @test_call target_modules=target_modules parse_place(node, pntd)

        @test pid(n) === :place1
        @test @inferred(pid(n)) === :place1
        @test has_name(n)
        @test @inferred(name(n)) == "with text"
        @test_call target_modules=(@__MODULE__,) initial_marking(n)
        im = initial_marking(n)
    end
end

@testset "transition $pntd" for pntd in PnmlTypeDefs.all_nettypes()
    node = xml"""
      <transition id="transition1">
        <name> <text>Some transition</text> </name>
        <condition> <text>always true</text>
                    <structure> <booleanconstant value="true"/></structure>
        </condition>
      </transition>
    """
    @with PNML.idregistry => PnmlIDRegistry() PNML.DECLDICT => DeclDict() begin
        PNML.fill_nonhl!(PNML.DECLDICT[])
        n = @inferred Transition parse_transition(node, PnmlCoreNet())
        @test n isa Transition
        @test pid(n) === :transition1
        @test has_name(n)
        @test name(n) == "Some transition"
        @test condition(n)() isa Bool

        node = xml"""<transition id ="t1"> <condition><text>test w/o structure</text></condition></transition>"""
        @test_throws PNML.MalformedException parse_transition(node, pntd)

        node = xml"""<transition id ="t2"> <condition/> </transition>"""
        @test_throws Exception parse_transition(node, pntd)

        node = xml"""<transition id ="t3"> <condition><structure/></condition> </transition>"""
        @test_throws "ArgumentError: missing condition term in <structure>" parse_transition(node, pntd)

        node = xml"""<transition id ="t4">
            <condition>
            <text>test true 1</text>
                <structure> true </structure>
            </condition>
        </transition>"""
        @test_throws "ArgumentError: missing condition term in <structure>" parse_transition(node, pntd)

        node = xml"""<transition id ="t5">
            <condition>
                <text>test true 2</text>
                <structure> <booleanconstant value="true"/> </structure>
            </condition>
        </transition>"""
        t = parse_transition(node, pntd)
        @test t isa Transition
        @test condition(t)() === true
    end
end

println("\n==============================================================================")

@testset "delay label $pntd" for pntd in PnmlTypeDefs.all_nettypes()
   @with PNML.idregistry => PnmlIDRegistry() PNML.DECLDICT => DeclDict() begin
        PNML.fill_nonhl!(PNML.DECLDICT[])
         # From [Tina .pnml formt](file://~/PetriNet/tina-3.7.5/doc/html/formats.html#5)
        # This bit may be from the pre-standard era.
        # <ci> is a variable(constant) like pi, infinity.
        # <cn> is a number (real)
        # interval [4,9]
        node = xml"""<transition id ="t6">
            <delay>
                <interval xmlns="http://www.w3.org/1998/Math/MathML" closure="closed">
                    <cn>4.0</cn>
                    <cn>9</cn>
                </interval>
            </delay>
        </transition>"""
        t = parse_transition(node, pntd)::Transition
        @test has_label(labels(t), "delay")
        #@show PNML.get_label(labels(t), "delay") #! debug
        #@show PNML.labelof(t, "delay") #! debug
        @test PNML.get_label(labels(t), "delay") == PNML.labelof(t, "delay")
        @test PNML.delay_value(t) isa Tuple
        #println()

        # unbounded interval [4,∞)
        node = xml"""<transition id ="t7">
            <delay>
                <interval xmlns="http://www.w3.org/1998/Math/MathML" closure="closed-open">
                    <cn>4</cn>
                    <ci>infty</ci>
                </interval>
            </delay>
        </transition>"""
        t = parse_transition(node, pntd)::Transition
        @test PNML.delay_value(t) isa Tuple
        #@show PNML.labelof(t, "delay") #! debug
        #println()

        # interval (3,5)
        node = xml"""<transition id ="t8">
            <delay>
                <interval xmlns="http://www.w3.org/1998/Math/MathML" closure="open">
                    <cn>3</cn>
                    <cn>5</cn>
                </interval>
            </delay>
        </transition>"""
        t = parse_transition(node, pntd)::Transition
        @test PNML.delay_value(t) isa Tuple
        #@show PNML.labelof(t, "delay") #! debug
        #println()
    end
end

#! Needs scaffolding
# @testset "arc $pntd"  for pntd in PnmlTypeDefs.all_nettypes()
#     insc_xml = if ishighlevel(pntd)
#         """<hlinscription>
#             <text>6</text>
#             <structure> 6 </structure>
#            </hlinscription>"""
#     else
#         """<inscription> <text>6</text> </inscription>"""
#     end

#     node = xml"""
#       <arc source="transition1" target="place1" id="arc1">
#         <name> <text>Some arc</text> </name>
#         $insc_xml
#         <unknown id="unkn">
#             <name> <text>unknown label</text> </name>
#             <text>content text</text>
#         </unknown>
#       </arc>
#     """
#     PNML.CONFIG[].warn_on_unclaimed = true
#     if ishighlevel(pntd)
#         @test_throws("ArgumentError: missing inscription term in <structure>",
#                     parse_arc(node, pntd), netdata=PNML.PnmlNetData()))
#     else
#         a1 = @test_logs(match_mode=:any,
#                 (:warn, "found unexpected child of <arc>: unknown"),
#                 parse_arc(node, pntd), netdata=PNML.PnmlNetData()))
#         a2 = Arc(a1, Ref(:newsrc), Ref(:newtarget))
#         @testset "a1,a2" for a in [a1, a2]
#             @test typeof(a) <: Arc
#             @test pid(a) === :arc1
#             @test has_name(a)
#             @test name(a) == "Some arc"
#             @test_call  inscription(a)
#             @test inscription(a) == 6
#         end
#     end
# end

@testset "ref Trans $pntd" for pntd in PnmlTypeDefs.all_nettypes()
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
    @with PNML.idregistry => PnmlIDRegistry() PNML.DECLDICT => PNML.DeclDict() begin
        PNML.fill_nonhl!(PNML.DECLDICT[])
        n = if PNML.CONFIG[].warn_on_unclaimed == true
            @test_logs((:warn, "^ignoring unexpected child"),
                    parse_refTransition(node, pntd)::RefTransition)
        else
            parse_refTransition(node, pntd)::RefTransition
        end
        @test pid(n) === :rt1
        @test PNML.refid(n) === :t1
        @test PNML.has_graphics(n) && startswith(repr(PNML.graphics(n)), "Graphics")
    end
end

@testset "ref Place $pntd" for pntd in PnmlTypeDefs.all_nettypes()
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
        @with PNML.idregistry => PnmlIDRegistry()  PNML.DECLDICT => PNML.DeclDict() begin
            PNML.fill_nonhl!(PNML.DECLDICT[])
            n = if PNML.CONFIG[].warn_on_unclaimed
                @test_logs(match_mode=:any, (:warn, r"^ignoring unexpected child"),
                        parse_refPlace(s.node, ContinuousNet())::RefPlace)
            else
                parse_refPlace(s.node, ContinuousNet())::RefPlace
           end
            @test pid(n) === Symbol(s.id)

            @test PNML.refid(n) === Symbol(s.ref)
        end
    end
end
