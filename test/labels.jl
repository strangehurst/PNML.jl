using PNML, ..TestUtils, JET, NamedTupleTools, OrderedCollections
using EzXML: EzXML
using XMLDict: XMLDict
const NON_HL_NETS = tuple(PnmlCoreNet(), ContinuousNet())

@testset "text $pntd" for pntd in PnmlTypes.core_nettypes()
    @test parse_text(xml"<text>ready</text>", pntd) == "ready"
end

#------------------------------------------------
@testset "name $pntd" for pntd in PnmlTypes.core_nettypes()
    parse_context = PNML.parser_context()
    n = @test_logs (:warn, r"^<name> missing <text>") PNML.Parser.parse_name(xml"<name></name>", pntd; parse_context, parentid=:xxx)
    @test n isa PNML.AbstractLabel
    @test PNML.text(n) == ""

    n = @test_logs (:warn, r"^<name> missing <text>") PNML.Parser.parse_name(xml"<name>stuff</name>", pntd; parse_context, parentid=:xxx)
    @test PNML.text(n) == "stuff"

    @test n.graphics === nothing
    @test n.toolspecinfos === nothing || isempty(n.toolspecinfos)

    n = PNML.Parser.parse_name(xml"<name><text>some name</text></name>", pntd; parse_context, parentid=:xxx)
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
    node = xmlnode("""
    <initialMarking>
        <text> $(iscontinuous(pntd) ? "123.0" : "123") </text>
        <toolspecific tool="org.pnml.tool" version="1.0">
            <tokengraphics> <tokenposition x="6" y="9"/> </tokengraphics>
        </toolspecific>
        <unknown id="unkn">
            <name> <text>unknown label</text> </name>
            <text>content text</text>
        </unknown>
    </initialMarking>
    """)
    #println(str)

    parse_context = PNML.parser_context()
    @show PNML.value_type(PNML.Marking, pntd)
    @show PNML.Labels._sortref(parse_context.ddict, PNML.value_type(PNML.Marking, pntd))

    placetype = SortType("$pntd initMarking",
        PNML.Labels._sortref(parse_context.ddict, PNML.value_type(PNML.Marking, pntd))::AbstractSortRef,
        nothing, nothing, parse_context.ddict)

    # Parse ignoring unexpected child
    mark = @test_logs(match_mode=:any, (:warn, r"^ignoring unexpected child"),
                parse_initialMarking(node, placetype, pntd; parse_context, parentid=:xxx)::PNML.Marking)
    #@test typeof(value(mark)) <: Union{Int,Float64}
    @test mark()::Union{Int,Float64} == 123

    # Integer
    mark1 = PNML.Marking(23, parse_context.ddict)
    @test_opt broken=false PNML.Marking(23, parse_context.ddict)
    @test_call PNML.Marking(23, parse_context.ddict)
    @test typeof(mark1()) == typeof(23)
    @test mark1() == 23
    @test_opt broken=false mark1()
    @test_call mark1()

    @test graphics(mark1) === nothing
    @test toolinfos(mark1) === nothing || isempty(toolinfos(mark1))

    # Floating point
    mark2 = PNML.Marking(3.5, parse_context.ddict)
    #@show mark2 mark2()
    @test_opt broken=false PNML.Marking(3.5, parse_context.ddict)
    @test_call PNML.Marking(3.5, parse_context.ddict)
    @test typeof(mark2()) == typeof(3.5)
    @test mark2() ≈ 3.5
    @test_call mark2()
    @test graphics(mark2) === nothing
    @test toolinfos(mark2) === nothing || isempty(toolinfos(mark2))
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
    parse_context = PNML.parser_context()
    inscript = @test_logs(match_mode=:any,
                    (:warn, r"^ignoring unexpected child of <inscription>: 'unknown'"),
                    parse_inscription(n1, :nothing, :nothing, pntd;
                            netdata=PnmlNetData(), parse_context, parentid=:xxx))
    @test inscript isa PNML.Inscription
    #@test_broken typeof(eval(value(inscript))) <: Union{Int,Float64}
    #@show inscript
    #@test_broken inscript() == 12
    #@test graphics(inscript) !== nothing
    #@test toolinfos(inscript) === nothing || !isempty(toolinfos(inscript))
    #@test_throws MethodError labels(inscript)

    #@test occursin("Graphics", sprint(show, inscript))
end

FF(@nospecialize f) = f !== EZXML.throw_xml_error;

#@testset "add_labels JET $pntd" for pntd in PnmlTypes.core_nettypes()
    # lab = PnmlLabel[]
    # reg = IDRegistry()
    # @show pff(PNML.Parser.add_label!) pff(PNML.xmldict) pff(PNML.extralabels)
    # @test_opt PNML.Parser.add_label!(lab, node, pntd)
    # @test_opt(broken=false,
    #             ignored_modules=(JET.AnyFrameModule(EzXML),
    #                             JET.AnyFrameModule(XMLDict),
    #                             JET.AnyFrameModule(Base.CoreLogging)),
    #             function_filter=pff,
    #             PNML.Parser.add_label!(lab, xml"""<test1> 1 </test1>""", pntd))

    # @test_call PNML.Parser.add_label!(lab, node, pntd)
    # @test_call(ignored_modules=(JET.AnyFrameModule(EzXML),
    #                             JET.AnyFrameModule(XMLDict)),
    #                             PNML.Parser.add_label!(lab, node, pntd))
#end

@testset "labels $pntd" for pntd in PnmlTypes.core_nettypes()
    parse_context = PNML.parser_context()
    lab = OrderedCollections.LittleDict{Symbol,Any}() # PnmlLabel[]
    for i in 1:4 # create & add 4 labels
        x = i < 3 ? 1 : 2 # make 2 different tagnames
        str = "<test$x> $i </test$x>"
        PNML.Parser.add_label!(lab, xmlnode(str), pntd, parse_context)
        #@show lab
    end
    @test length(lab) == 2
    #@show lab
    # for l in values(lab)
    #     @test_opt tag(l)
    #     @test_call tag(l)
    #     @test tag(l) === :test1 || tag(l) === :test2
    # end

    # @test_call has_label(lab, :test1)
#    @test_call get_label(lab, :test1)
    @test_call labels(lab, :test1)
    @test_call labels(lab, :test2)

    # @test has_key(lab, :test1)
    # @test !has_key(lab, :bumble)

    # v = @inferred PnmlLabel get_label(lab, :test2)
    # @test v isa PnmlLabel
    # @test tag(v) === :test2
    # @test elements(v) == "3"

    # @testset "label $labeltag" for labeltag in [:test1, :test2]
    #     vec = PNML.labels(lab, labeltag)
    #     lv = 0
    #     for l in vec
    #         @test tag(l) === labeltag
    #         lv += 1
    #     end
    #     @test lv == 2
    # end
end

"Return PnmlLabel, AnyElement"
function test_unclaimed(pntd, xmlstring::String)
    parse_context = PNML.parser_context()
    node = xmlnode(xmlstring)::XMLNode
    reg1 = IDRegistry()# 2 registries to ensure any ids do not collide.
    reg2 = IDRegistry()

    nodeid = Symbol(EzXML.nodename(node))
    u = Parser.xmldict(node) # tag is a string
    l = PnmlLabel(nodeid, u, parse_context.ddict)
    a = anyelement(nodeid, node)

    @test u isa PNML.DictType
    @test l isa PnmlLabel
    @test a isa AnyElement

    @test_opt target_modules=(@__MODULE__,) Parser.xmldict(node)
    @test_opt target_modules=(@__MODULE__,) function_filter=pff PnmlLabel(nodeid,u,parse_context.ddict)
    @test_opt target_modules=(@__MODULE__,) function_filter=pff Parser.anyelement(nodeid, node)

    @test_call ignored_modules=(JET.AnyFrameModule(EzXML),
                            JET.AnyFrameModule(XMLDict)) Parser.xmldict(node)
    @test_call ignored_modules=(JET.AnyFrameModule(EzXML),
                            JET.AnyFrameModule(XMLDict)) PnmlLabel(nodeid,u,parse_context.ddict)
    @test_call ignored_modules=(JET.AnyFrameModule(EzXML),
                            JET.AnyFrameModule(XMLDict)) Parser.anyelement(nodeid, node)

    nn = Symbol(EzXML.nodename(node))
    @test tag(l) isa Symbol && tag(l) === nn || tag(l) == string(nn)
    @test tag(a) isa Symbol && tag(a) === nn || tag(a) == string(nn)

    @test u isa DictType
    @test l.elements isa DictType
    @test a.elements isa LittleDict
    #! unclaimed id is not registered
    x = get(u, :id, nothing)
    !isnothing(x) &&
        @test !isregistered(parse_context.idregistry, Symbol(x))
    return l, a
end

@testset "unclaimed $pntd" for pntd in PnmlTypes.core_nettypes()
    # Even though they are "claimed" by having a parser, they still may be treated as unclaimed.
    # For example <declarations>.
    parse_context = PNML.parser_context()

    ctrl = [ # Vector of tuples of XML string, expected result from `XMLDict.xml_dict`.
        ("""<declarations> </declarations>""",
            "declarations" => DictType()),

        ("""<declarations atag="atag1"> </declarations>""",
            "declarations" => DictType(:atag =>"atag1")),

        ("""<foo><declarations> </declarations></foo>""",
            "foo" => DictType("declarations" => DictType())),

        # no content, no attribute maybe results in empty tuple.
        ("""<null></null>""",
            "null" => DictType()),
        ("""<null2/>""",
            "null2" => DictType()),
        # no content, with attribute
        ("""<null at="null"></null>""",
            "null" => DictType(:at => "null")),
        ("""<null2 at="null2" />""",
            "null2" => DictType(:at => "null2")),
        # empty content, no attribute
        ("""<empty> </empty>""",
            "empty" => DictType()),
        # empty content, with attribute
        ("""<empty at="empty"> </empty>""",
            "empty" => DictType(:at => "empty")),
        # unclaimed do not register id
        ("""<foo id="testid1" />""",
            "foo" => DictType(:id => "testid1")),
        ("""<foo id="testid2"/>""",
            "foo" => DictType(:id => "testid2")),

        ("""<foo id="repeats">
                <one>ONE</one>
                <one>TWO</one>
                <one>TRI</one>
            </foo>""",
            "foo" => DictType(:id => "repeats",
                            "one" => Any["ONE", "TWO", "TRI"])),

        ("""<declarations atag="atag2">
                <something> some content </something>
                <something> other stuff </something>
                <something2 tag2="tagtwo">
                    <value/>
                    <value tag3="tagthree"/>
                </something2>
            </declarations>""",
            "declarations"=> DictType(:atag => "atag2",
                        "something" => Any["some content", "other stuff"],
                        "something2" =>
                            DictType(:tag2 => "tagtwo",
                                "value" => Any[DictType(), DictType(:tag3 => "tagthree")]))),
    ]
    # expected is a pair to construct a PnmlLabel
    for (s, expected) in ctrl
        lab, anye = test_unclaimed(pntd, s)
        # TODO Add equality test, skip xml node.
        expected_label = PnmlLabel(Symbol(expected.first), expected.second, parse_context.ddict)
        @test tag(lab) == tag(expected_label)
        @test length(elements(lab)) == length(elements(expected_label))
        # TODO recursive compare
        expected_any = AnyElement(Symbol(expected.first), expected.second)
        @test tag(anye) == tag(expected_any)
        @test length(elements(anye)) == length(elements(expected_any))
        # TODO recursive compare
    end
end
