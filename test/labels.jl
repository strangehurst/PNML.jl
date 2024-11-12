using PNML, ..TestUtils, JET, NamedTupleTools, AbstractTrees
using EzXML: EzXML
using XMLDict: XMLDict
const NON_HL_NETS = tuple(PnmlCoreNet(), ContinuousNet())

@testset "text $pntd" for pntd in core_nettypes()
    @with PNML.idregistry=>registry() @test parse_text(xml"<text>ready</text>", pntd) == "ready"
end

#------------------------------------------------
@testset "name $pntd" for pntd in core_nettypes()
    n = @test_logs (:warn, r"^<name> missing <text>") PNML.parse_name(xml"<name></name>", pntd)
    @test n isa PNML.AbstractLabel
    @test PNML.text(n) == ""

    n = @test_logs (:warn, r"^<name> missing <text>") PNML.parse_name(xml"<name>stuff</name>", pntd)
    @test PNML.text(n) == "stuff"

    @test n.graphics === nothing
    @test n.tools === nothing || isempty(n.tools)

    n = PNML.parse_name(xml"<name><text>some name</text></name>", pntd)
    @test n isa PNML.Name
    @test PNML.text(n) == "some name"
    #TODO add parse_graphics
    #TODO add toolinfo
end
#------------------------------------------------
#------------------------------------------------
#------------------------------------------------
#------------------------------------------------
#------------------------------------------------
@testset "PT initMarking $pntd" for pntd in NON_HL_NETS
    text_value = iscontinuous(pntd) ? "123.0" : "123"
    str = """
    <initialMarking>
        <text> $text_value </text>
        <toolspecific tool="org.pnml.tool" version="1.0">
            <tokengraphics> <tokenposition x="6" y="9"/> </tokengraphics>
        </toolspecific>
        <unknown id="unkn">
            <name> <text>unknown label</text> </name>
            <text>content text</text>
        </unknown>
    </initialMarking>
    """
    #println(str)
    node = xmlroot(str)

    @with PNML.idregistry => registry() PNML.DECLDICT => PNML.DeclDict() begin
        PNML.fill_nonhl!()
        @show marking_value_type(pntd)
        placetype = SortType("$pntd initMarking", sortref(marking_value_type(pntd))::UserSort)

        # Parse ignoring unexpected child
        mark = @test_logs((:warn, r"^ignoring unexpected child"),
                    parse_initialMarking(node, placetype, pntd)::PNML.Marking)
        #@test typeof(value(mark)) <: Union{Int,Float64}
        @test mark()::Union{Int,Float64} == 123

        # Integer
        mark1 = PNML.Marking(23)
        @test_opt PNML.Marking(23)
        @test_call PNML.Marking(23)
        @test typeof(mark1()) == typeof(23)
        @test mark1() == 23
        @test_opt broken=false mark1()
        @test_call mark1()

        @test graphics(mark1) === nothing
        @test tools(mark1) === nothing || isempty(tools(mark1))

        # Floating point
        mark2 = PNML.Marking(3.5)
        @test_opt PNML.Marking(3.5)
        @test_call PNML.Marking(3.5)
        @test typeof(mark2()) == typeof(3.5) #! term rewrite, _evaluate
        @test mark2() ≈ 3.5
        @test_call mark2()

        @test graphics(mark2) === nothing
        @test tools(mark2) === nothing || isempty(tools(mark2))
    end
end

@testset "PT inscription $pntd" for pntd in NON_HL_NETS
    n1 = xml"""<inscription>
        <text> 12 </text>
        <graphics><offset x="0" y="0"/></graphics>
        <toolspecific tool="org.pnml.tool" version="1.0">
            <tokengraphics> <tokenposition x="6" y="9"/> </tokengraphics>
        </toolspecific>
        <unknown id="unkn">
            <name> <text>unknown label</text> </name>
            <text>unknown content text</text>
        </unknown>
    </inscription>"""
    @with PNML.idregistry => registry() PNML.DECLDICT => PNML.DeclDict() begin
        PNML.fill_nonhl!(PNML.DECLDICT[])
        inscript = @test_logs((:warn, r"^ignoring unexpected child of <inscription>: 'unknown'"),
                            parse_inscription(n1, :nothing, :nothing, pntd))
        @test inscript isa PNML.Inscription
        #@test_broken typeof(eval(value(inscript))) <: Union{Int,Float64}
        @show inscript
        #@test_broken inscript() == 12 #! term rewrite, _evaluate
        #@test graphics(inscript) !== nothing
        #@test tools(inscript) === nothing || !isempty(tools(inscript))
        #@test_throws MethodError labels(inscript)

        #@test occursin("Graphics", sprint(show, inscript))
    end
end

FF(@nospecialize f) = f !== EZXML.throw_xml_error;

#@testset "add_labels JET $pntd" for pntd in core_nettypes()
    # lab = PnmlLabel[]
    # reg = registry()
    # @show pff(PNML.add_label!) pff(PNML.unparsed_tag) pff(PNML.labels)
    # @test_opt add_label!(lab, node, pntd)
    # @test_opt(broken=false,
    #             ignored_modules=(JET.AnyFrameModule(EzXML),
    #                             JET.AnyFrameModule(XMLDict),
    #                             JET.AnyFrameModule(Base.CoreLogging)),
    #             function_filter=pff,
    #             add_label!(lab, xml"""<test1> 1 </test1>""", pntd))

    # @test_call add_label!(lab, node, pntd)
    # @test_call(ignored_modules=(JET.AnyFrameModule(EzXML),
    #                             JET.AnyFrameModule(XMLDict)),
    #                             add_label!(lab, node, pntd))
#end

@testset "labels $pntd" for pntd in core_nettypes()
    lab = PnmlLabel[]
    reg = registry()
    for i in 1:4 # create & add 4 labels
        x = i < 3 ? 1 : 2 # make 2 different tagnames
        node = xmlroot("<test$x> $i </test$x>")::XMLNode

        lab = Parser.add_label!(lab, node, pntd)
        @test lab isa Vector{PnmlLabel}
        @test length(lab) == i
    end
    @test length(lab) == 4

    for l in lab
        @test_opt tag(l)
        @test_call tag(l)
        @test tag(l) === :test1 || tag(l) === :test2
    end

    @test_call has_label(lab, :test1)
    @test_call get_label(lab, :test1)
    @test_call get_labels(lab, :test1)

    @test has_label(lab, :test1)
    @test !has_label(lab, :bumble)

    v = get_label(lab, :test2)
    @test v isa PnmlLabel
    @test tag(v) === :test2
    @test elements(v) == "3"

    @testset "label $labeltag" for labeltag in [:test1, :test2]
        vec = PNML.get_labels(lab, labeltag)
        lv = 0
        for l in vec
            @test tag(l) === labeltag
            lv += 1
        end
        @test lv == 2
    end
end

function test_unclaimed(pntd, xmlstring::String)
    node::XMLNode = xmlroot(xmlstring)
    reg1 = registry()# 2 registries to ensure any ids do not collide.
    reg2 = registry()
    @with PNML.idregistry => reg2 PNML.DECLDICT => PNML.DeclDict() begin
        PNML.fill_nonhl!(PNML.DECLDICT[];)
        (t,u) = unparsed_tag(node) # tag is a string
        l = PnmlLabel(t, u)
        a = anyelement(node, pntd)

        @test u isa PNML.DictType
        @test l isa PnmlLabel
        @test a isa AnyElement

        @test_opt target_modules=(@__MODULE__,) unparsed_tag(node)
        @test_opt target_modules=(@__MODULE__,) function_filter=pff PnmlLabel(t,u)
        @test_opt target_modules=(@__MODULE__,) function_filter=pff anyelement(node, pntd)

        @test_call ignored_modules=(JET.AnyFrameModule(EzXML),
                                JET.AnyFrameModule(XMLDict)) unparsed_tag(node)
        @test_call ignored_modules=(JET.AnyFrameModule(EzXML),
                                JET.AnyFrameModule(XMLDict)) PnmlLabel(t,u)
        @test_call ignored_modules=(JET.AnyFrameModule(EzXML),
                                JET.AnyFrameModule(XMLDict)) anyelement(node, pntd)

        nn = Symbol(EzXML. EzXML.nodename(node))
        @test t == EzXML.nodename(node)
        @test tag(l) === nn
        @test tag(a) === nn

        @test u isa DictType
        @test l.elements isa DictType
        @test a.elements isa DictType
        #! unclaimed id is not registered
        x = get(u, :id, nothing)
        !isnothing(x) &&
            @with PNML.idregistry => reg1 @test !isregistered(PNML.idregistry[], Symbol(x))
        return l, a
        end
end

@testset "unclaimed $pntd" for pntd in core_nettypes()
    # Even though they are "claimed" by having a parser, they still may be treated as unclaimed.
    # For example <declarations>.
    ctrl = [ # Vector of tuples of XML string, expected result `Pair`.
        ("""<declarations> </declarations>""",
            :declarations => DictType()),

        ("""<declarations atag="atag1"> </declarations>""",
            :declarations => DictType(:atag =>"atag1")),

        ("""<foo><declarations> </declarations></foo>""",
            :foo => DictType("declarations" => DictType())),

        # no content, no attribute maybe results in empty tuple.
        ("""<null></null>""",
            :null => DictType()),
        ("""<null2/>""",
            :null2 => DictType()),
        # no content, with attribute
        ("""<null at="null"></null>""",
            :null => DictType(:at => "null")),
        ("""<null2 at="null2" />""",
            :null2 => DictType(:at => "null2")),
        # empty content, no attribute
        ("""<empty> </empty>""",
            :empty => DictType()),
        # empty content, with attribute
        ("""<empty at="empty"> </empty>""",
            :empty => DictType(:at => "empty")),
        # unclaimed do not register id
        ("""<foo id="testid1" />""",
            :foo => DictType(:id => "testid1")),
        ("""<foo id="testid2"/>""",
            :foo => DictType(:id => "testid2")),

        ("""<foo id="repeats">
                <one>ONE</one>
                <one>TWO</one>
                <one>TRI</one>
            </foo>""",
            :foo => DictType(:id => "repeats",
                            "one" => Any["ONE", "TWO", "TRI"])),

        ("""<declarations atag="atag2">
                <something> some content </something>
                <something> other stuff </something>
                <something2 tag2="tagtwo">
                    <value/>
                    <value tag3="tagthree"/>
                </something2>
            </declarations>""",
            :declarations => DictType(:atag => "atag2",
                        "something" => Any["some content", "other stuff"],
                        "something2" =>
                            DictType(:tag2 => "tagtwo",
                                "value" => Any[DictType(), DictType(:tag3 => "tagthree")]))),
    ]
    # expected is a pair to construct a PnmlLabel
    for (s, expected) in ctrl
        lab, anye = test_unclaimed(pntd, s)
        # TODO Add equality test, skip xml node.
        expected_label = PnmlLabel(expected...)
        @test tag(lab) == tag(expected_label)
        @test length(elements(lab)) == length(elements(expected_label))
        # TODO recursive compare
        expected_any = AnyElement(expected...)
        @test tag(anye) == tag(expected_any)
        @test length(elements(anye)) == length(elements(expected_any))
        # TODO recursive compare
    end
end
