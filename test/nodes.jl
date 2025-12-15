using PNML, ..TestUtils, JET, XMLDict

#---------------------------------------------
# PLACE
#---------------------------------------------

@testset "place $pntd" for pntd in PnmlTypes.all_nettypes(!ishighlevel)
    node = xml"""
        <place id="place1">
        <name> <text>with text</text> </name>
        <initialMarking>
            <text>100</text>
            <!-- standard does not use/allow structure here
            <structure><numberconstant value="100"><integer/></numberconstant></structure>
            -->
        </initialMarking>
        </place>
    """
    ctx = PNML.parser_context()

    placetype = SortType("XXX", NamedSortRef(:natural), nothing, nothing, ctx.ddict)

    n  = parse_place(node, pntd; parse_context=ctx)::Place
    @test_opt target_modules=(@__MODULE__,) parse_place(node, pntd; parse_context=ctx)
    @test_call target_modules=target_modules parse_place(node, pntd; parse_context=ctx)
    @test @inferred(pid(n)) === :place1
    @test has_name(n)
    @test @inferred(name(n)) == "with text"
    @test_call initial_marking(n)
    #@show pntd, initial_marking(n)
    @test initial_marking(n)::Number == 100
end

@testset "place $pntd" for pntd in PnmlTypes.all_nettypes(ishighlevel)
    node = xml"""
        <place id="place1">
        <name> <text>with text</text> </name>
        <type><structure><dot/></structure></type>
        <hlinitialMarking>
            <text>101</text>
            <structure>
            <numberof>
                <subterm><numberconstant value="101"><positive/></numberconstant></subterm>
                <subterm><dotconstant/></subterm>
            </numberof>
            </structure>
        </hlinitialMarking>
        </place>
    """
    ctx = PNML.parser_context()

    n = parse_place(node, pntd; parse_context=ctx)::Place
    @test_call target_modules=target_modules parse_place(node, pntd; parse_context=ctx)

    @test @inferred(pid(n)) === :place1
    @test has_name(n)
    @test @inferred(name(n)) == "with text"
    @test_call target_modules=(@__MODULE__,) initial_marking(n)
    #@show pntd, initial_marking(n)
    @test PNML.cardinality(initial_marking(n)::PnmlMultiset) == 101
end

@testset "place unknown label $pntd" for pntd in PnmlTypes.all_nettypes(ishighlevel)
    node = xml"""
        <place id="place1">
        <type><structure><dot/></structure></type>
        <hlinitialMarking>
            <text>101</text>
            <structure>
            <numberof>
                <subterm><numberconstant value="101"><positive/></numberconstant></subterm>
                <subterm><dotconstant/></subterm>
            </numberof>
            </structure>
        </hlinitialMarking>
        <somelabel1 a="text">
            <another b="more" />
        </somelabel1>
        <somelabel2 c="value" />
        </place>
    """
    ctx = PNML.parser_context()
    n = @test_logs((:info, "add PnmlLabel :somelabel1 to :place1"),
                   (:info, "add PnmlLabel :somelabel2 to :place1"),
                    parse_place(node, pntd; parse_context=ctx)::Place)
    @test pid(n) === :place1
    @test has_name(n) == false
    @test PNML.has_labels(n) == true
    #@show labels(n)
    #@show keys(labels(n))
    #@show labels(n)[:somelabel1]
    #@show labels(n)[:somelabel2]
    #@show elements(labels(n)[:somelabel1])
    @test elements(labels(n)[:somelabel1])[:a] == "text"
    @test elements(labels(n)[:somelabel1])["another"][:b] == "more"
    #@show elements(labels(n)[:somelabel2])
    @test elements(labels(n)[:somelabel2])[:c] == "value"
end


#---------------------------------------------
# TRANSITION
#---------------------------------------------

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
    @test isempty(PNML.Labels.variables(condition(n))::Vector{Symbol})

    @test varsubs(n) isa Vector{NamedTuple}
    @test isempty(varsubs(n))

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

@testset "transition unknown label $pntd" for pntd in PnmlTypes.all_nettypes()
    node = xml"""
      <transition id="transition1">
        <name> <text>Some transition</text> </name>
        <condition> <text>always true</text>
                    <structure><booleanconstant value="true"/></structure>
        </condition>
        <somelabel2 c="value" />
     </transition>
    """
    parse_context = PNML.parser_context()

   n = @test_logs((:info, "add PnmlLabel :somelabel2 to :transition1"),
                parse_transition(node, PnmlCoreNet(); parse_context)::Transition)
    @test pid(n) === :transition1
    @test PNML.has_labels(n) == true
    @test elements(labels(n)[:somelabel2])[:c] == "value"
end

#---------------------------------------------
# ARC
#---------------------------------------------

using PNML: isnormal, isinhibitor, isread, isreset

@testset "arctypes $arct" for arct in ["normal", "inhibitor", "read", "reset"]
    pntd = PnmlCoreNet()

    str = """<arc source="t1" target="p1" id="a1">
        <arctype>
            <text> $arct </text>
        </arctype>
      </arc>"""
    #@show str
    node = xmlnode(str)
    PNML.CONFIG[].warn_on_unclaimed = true
    parse_context = PNML.Parser.parser_context()

    a = parse_arc(node, pntd, netdata=PNML.PnmlNetData(); parse_context)::Arc
    atl = PNML.arctypelabel(a)
    arct = PNML.Labels.arctype(atl)

    @test length(Base.findall([isnormal(a), isinhibitor(a), isread(a), isreset(a)])) == 1
    @test length(Base.findall([isnormal(atl), isinhibitor(atl), isread(atl), isreset(atl)])) == 1
    @test length(Base.findall([isnormal(arct), isinhibitor(arct), isread(arct), isreset(arct)])) == 1

    @test isnormal(a) == isnormal(atl) == isnormal(arct)
    @test isinhibitor(a) == isinhibitor(atl) ==isinhibitor(arct)
    @test isread(a) == isread(atl) == isread(arct)

    @test pid(a) === :a1
    @test !has_name(a)
    @test inscription(a)(NamedTuple()) == 1
end

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

#     node = xmlnode("""
#       <arc source="transition1" target="place1" id="arc1">
#         <name> <text>Some arc</text> </name>
#         $insc_xml
#         <unknown id="unkn">
#             <name> <text>unknown label</text> </name>
#             <text>content text</text>
#         </unknown>
#       </arc>
#     """)
#     PNML.CONFIG[].warn_on_unclaimed = true
#     parse_context = PNML.Parser.parser_context()
#     if ishighlevel(pntd)
#         @test_throws("ArgumentError: missing inscription term in <structure>",
#                     parse_arc(node, pntd, netdata=PNML.PnmlNetData(); parse_context))
#     else
#         a = @test_logs(match_mode=:any,
#                 (:warn, "found unexpected child of <arc>: unknown"),
#                 parse_arc(node, pntd, netdata=PNML.PnmlNetData(); parse_context))

#         @test typeof(a) <: Arc
#         @test pid(a) === :arc1
#         @test has_name(a)
#         @test name(a) == "Some arc"
#         @test_call  inscription(a)
#         @test inscription(a)(NamedTuple()) == 6
#     end
# end

#---------------------------------------------
# REFERENCE TRANSITION
#---------------------------------------------

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

@testset "ref Trans unknown label $pntd" for pntd in PnmlTypes.all_nettypes()
    node = xml"""
    <referenceTransition id="rt1" ref="t1">
        <name> <text>refTrans name</text> </name>
        <graphics><offset x="0" y="0"/></graphics>
        <toolspecific tool="unknowntool" version="1.0"><atool x="0"/></toolspecific>
        <somelabel2 c="value" />
    </referenceTransition>
    """
    parse_context = PNML.parser_context()

    n = @test_logs((:info, "add PnmlLabel :somelabel2 to :rt1"),
            parse_refTransition(node, pntd; parse_context)::RefTransition)
    @test pid(n) === :rt1
    @test PNML.refid(n) === :t1
    @test PNML.has_graphics(n) && startswith(repr(PNML.graphics(n)), "Graphics")
    @test PNML.has_labels(n) == true
    @test elements(labels(n)[:somelabel2])[:c] == "value"
end

#---------------------------------------------
# REFERENCE PLACE
#---------------------------------------------

@testset "ref Place $pntd" for pntd in PnmlTypes.all_nettypes()
    node = xml"""
    <referencePlace id="rp1" ref="p1">
        <name>
            <text>refPlace name</text>
        </name>
        <graphics><offset x="0" y="0"/></graphics>
        <toolspecific tool="unknowntool" version="1.0"><atool x="0"/></toolspecific>
    </referencePlace>"""

    parse_context = PNML.parser_context()
    n = parse_refPlace(node, pntd; parse_context)::RefPlace
    @test pid(n) === :rp1
    @test PNML.refid(n) === :p1
end

@testset "ref Place $pntd" for pntd in PnmlTypes.all_nettypes()
    node = xml"""
    <referencePlace id="rp1" ref="p1">
        <name>
            <text>refPlace name</text>
        </name>
        <graphics><offset x="0" y="0"/></graphics>
        <toolspecific tool="unknowntool" version="1.0"><atool x="0"/></toolspecific>
        <somelabel2 c="value" />
    </referencePlace>"""

    parse_context = PNML.parser_context()
    n = @test_logs((:info, "add PnmlLabel :somelabel2 to :rp1"),
            parse_refPlace(node, pntd; parse_context)::RefPlace)
    @test pid(n) === :rp1
    @test PNML.refid(n) === :p1
    @test PNML.has_labels(n) == true
    @test elements(labels(n)[:somelabel2])[:c] == "value"
end
