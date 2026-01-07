using PNML, ..TestUtils, JET, XMLDict

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
    @test elements(labels(n)[:somelabel2])[:c] == "value"
    @test PNML.get_label(n, :somelabel2) != nothing
    @test PNML.get_label(n, :nosuchlabel) == nothing
    @test PNML.has_tools(n) == false
end

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
    @test elements(labels(n)[:somelabel2])[:c] == "value"
end
