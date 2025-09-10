using PNML, ..TestUtils, JET, XMLDict

@testset "place $pntd" for pntd in PnmlTypes.all_nettypes(!ishighlevel)
    node = xml"""
        <place id="place1">
        <name> <text>with text</text> </name>
        <initialMarking> <text>100</text> </initialMarking>
        </place>
    """
    ctx = PNML.parser_context()

    placetype = SortType("XXX", UserSortRef(:integer), nothing, nothing, ctx.ddict)

    n  = parse_place(node, pntd; parse_context=ctx)::Place
    @test_opt target_modules=(@__MODULE__,) parse_place(node, pntd; parse_context=ctx)
    @test_call target_modules=target_modules parse_place(node, pntd; parse_context=ctx)
    @test @inferred(pid(n)) === :place1
    @test has_name(n)
    @test @inferred(name(n)) == "with text"
    @test_call initial_marking(n)
    @test initial_marking(n) == 100
end

@testset "place $pntd" for pntd in PnmlTypes.all_nettypes(ishighlevel)
    node = xml"""
        <place id="place1">
        <name> <text>with text</text> </name>
        <hlinitialMarking> <text>100</text> </hlinitialMarking>
        </place>
    """
    ctx = PNML.parser_context()

    n = parse_place(node, pntd; parse_context=ctx)::Place
    @test_call target_modules=target_modules parse_place(node, pntd; parse_context=ctx)

    @test pid(n) === :place1
    @test @inferred(pid(n)) === :place1
    @test has_name(n)
    @test @inferred(name(n)) == "with text"
    @test_call target_modules=(@__MODULE__,) initial_marking(n)
    im = initial_marking(n)
end

@testset "transition $pntd" for pntd in PnmlTypes.all_nettypes()
    node = xml"""
      <transition id="transition1">
        <name> <text>Some transition</text> </name>
        <condition> <text>always true</text>
                    <structure> <booleanconstant value="true"/></structure>
        </condition>
      </transition>
    """
    parse_context = PNML.parser_context()

    n = @inferred Transition parse_transition(node, PnmlCoreNet(); parse_context)
    @test n isa Transition
    @test pid(n) === :transition1
    @test has_name(n)
    @test name(n) == "Some transition"
    #@show condition(n)()
    @test condition(n)() isa Bool

    node = xml"""<transition id ="t1"> <condition><text>test w/o structure</text></condition></transition>"""
    @test_throws PNML.MalformedException parse_transition(node, pntd; parse_context)

    node = xml"""<transition id ="t2"> <condition/> </transition>"""
    @test_throws Exception parse_transition(node, pntd; parse_context)

    node = xml"""<transition id ="t3"> <condition><structure/></condition> </transition>"""
    @test_throws "ArgumentError: missing condition term in <structure>" parse_transition(node, pntd; parse_context)

    node = xml"""<transition id ="t4">
        <condition>
        <text>test true 1</text>
            <structure> true </structure>
        </condition>
    </transition>"""
    @test_throws "ArgumentError: missing condition term in <structure>" parse_transition(node, pntd; parse_context)

    node = xml"""<transition id ="t5">
        <condition>
            <text>test true 2</text>
            <structure> <booleanconstant value="true"/> </structure>
        </condition>
    </transition>"""
    t = parse_transition(node, pntd; parse_context)
    @test t isa Transition
    @test condition(t)() === true
end

println("\n==============================================================================")


#! Needs scaffolding
# @testset "arc $pntd"  for pntd in PnmlTypes.all_nettypes()
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

@testset "ref Trans $pntd" for pntd in PnmlTypes.all_nettypes()
    node = xml"""
    <referenceTransition id="rt1" ref="t1">
        <name> <text>refTrans name</text> </name>
        <graphics><offset x="0" y="0"/></graphics>
        <toolspecific tool="unknowntool" version="1.0"><atool x="0"/></toolspecific>
    </referenceTransition>
    """
    parse_context = PNML.parser_context()

    n = parse_refTransition(node, pntd; parse_context)::RefTransition
    @test pid(n) === :rt1
    @test PNML.refid(n) === :t1
    @test PNML.has_graphics(n) && startswith(repr(PNML.graphics(n)), "Graphics")
end

@testset "ref Place $pntd" for pntd in PnmlTypes.all_nettypes()
    n1 = (node = xml"""
    <referencePlace id="rp2" ref="rp1">
        <name>
            <text>refPlace name</text>
        </name>
        <graphics><offset x="0" y="0"/></graphics>
        <toolspecific tool="unknowntool" version="1.0"><atool x="0"/></toolspecific>
    </referencePlace>""", id="rp2", ref="rp1" )

    n2 = (node = xml"""
    <referencePlace id="rp1" ref="Sync1">
        <graphics>
          <position x="734.5" y="41.5"/>
          <dimension x="40.0" y="40.0"/>
        </graphics>
    </referencePlace>""", id="rp1", ref="Sync1")

    @testset "referencePlaces" for s in [n1, n2]
        parse_context = PNML.parser_context()
        n = parse_refPlace(s.node, pntd; parse_context)::RefPlace
        @test pid(n) === Symbol(s.id)
        @test PNML.refid(n) === Symbol(s.ref)
    end
end
