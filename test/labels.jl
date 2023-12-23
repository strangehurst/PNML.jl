using PNML, EzXML, XMLDict, ..TestUtils, JET, NamedTupleTools, AbstractTrees

using PNML:
    Maybe, tag, XMLNode, xmlroot, labels,
    unparsed_tag, anyelement, PnmlLabel, AnyElement,
    has_label, get_label, get_labels, add_label!,
    default_marking, default_inscription, default_condition, default_sort,
    default_one_term, default_zero_term,
    has_graphics, graphics, has_name, name, has_label,
    value, tools, graphics, labels,
    parse_initialMarking, parse_inscription, parse_text,
    elements, all_nettypes, ishighlevel,
    DictType


@testset "text $pntd" for pntd in all_nettypes()
    @test parse_text(xml"<text>ready</text>", pntd, registry()) == "ready"
end

#------------------------------------------------
@testset "name $pntd" for pntd in all_nettypes()
    n = @test_logs (:warn, r"^<name> missing <text>") PNML.parse_name(xml"<name></name>", pntd, registry())
    @test n isa PNML.AbstractLabel
    @test PNML.text(n) == ""

    n = @test_logs (:warn, r"^<name> missing <text>") PNML.parse_name(xml"<name>stuff</name>", pntd, registry())
    @test PNML.text(n) == "stuff"

    @test n.graphics === nothing
    @test n.tools === nothing || isempty(n.tools)

    n = PNML.parse_name(xml"<name><text>some name</text></name>", pntd, registry())
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
@testset "PT initMarking $pntd" for pntd in all_nettypes()
    node = xml"""
    <initialMarking>
        <text>123</text>
        <toolspecific tool="org.pnml.tool" version="1.0">
            <tokengraphics> <tokenposition x="6" y="9"/> </tokengraphics>
        </toolspecific>
        <unknown id="unkn">
            <name> <text>unknown label</text> </name>
            <text>content text</text>
        </unknown>
    </initialMarking>
    """
    # Parse ignoring unexpected child
    mark = @test_logs (:warn, r"^ignoring unexpected child") parse_initialMarking(node, pntd, registry())
    # mark = @test_logs (:warn, "<initialMarking> ignoring unknown child 'unknown'") parse_initialMarking(node, pntd, registry())
    @test mark isa PNML.Marking
    @test typeof(value(mark)) <: Union{Int,Float64}
    @test value(mark) == mark() == 123

    # Integer
    mark1 = PNML.Marking(23)
    @test_opt PNML.Marking(23)
    @test_call PNML.Marking(23)
    @test typeof(mark1()) == typeof(23)
    @test mark1() == value(mark1) == 23
    @test_opt mark1()
    @test_call mark1()

    @test graphics(mark1) === nothing
    @test tools(mark1) === nothing || isempty(tools(mark1))

    # Floating point
    mark2 = PNML.Marking(3.5)
    @test_call PNML.Marking(3.5)
    @test typeof(mark2()) == typeof(3.5)
    @test mark2() == value(mark2) ≈ 3.5
    @test_call mark2()

    @test graphics(mark2) === nothing
    @test tools(mark2) === nothing || isempty(tools(mark2))
end

@testset "PT inscription $pntd" for pntd in all_nettypes()
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
    inscript = @test_logs (:warn, "ignoring unexpected child of <inscription>: unknown") parse_inscription(n1, pntd, registry())
    @test inscript isa PNML.Inscription
    @test typeof(value(inscript)) <: Union{Int,Float64}
    @test inscript() == value(inscript) == 12
    @test graphics(inscript) !== nothing
    @test tools(inscript) === nothing || !isempty(tools(inscript))
    @test_throws "does not have labels attached" labels(inscript) # === nothing || !isempty(labels(inscript))
end

@testset "labels $pntd" for pntd in all_nettypes()
    lab = PnmlLabel[]
    reg = registry()

    for i in 1:4 # create & add 4 labels
        x = i < 3 ? 1 : 2 # make 2 different tagnames
        node = xmlroot("<test$x> $i </test$x>")::XMLNode
        @test_call  ignored_modules=(JET.AnyFrameModule(EzXML),
                                      JET.AnyFrameModule(XMLDict)) add_label!(lab, node, pntd, reg)
        @test add_label!(lab, node, pntd, reg) isa PnmlLabel
        @test length(lab) == i
    end
    @test length(lab) == 4

    for l in lab
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
    if noisy
        println("+++++++++++++++++++")
        println("XML: ", xmlstring)
        println("-------------------")
    end
    node::XMLNode = xmlroot(xmlstring)
    reg1 = registry() # Need 2 test registries to ensure any ids do not collide.
    reg2 = registry() # Creating multiple things from the same string is not recommended.

    xdict = XMLDict.xml_dict(node, PNML.DictType)

    u = unparsed_tag(node, pntd) # tag is a string
    l = PnmlLabel(u)
    a = anyelement(node, pntd, reg2)

    if noisy
        println("u = $u ");
        println("l = $(l.tag) ");   dump(l)
        println("a = $(a.tag) " );  dump(a)
    end

    @test u isa PNML.DictType
    @test l isa PnmlLabel
    @test a isa AnyElement

    @test_opt target_modules=(@__MODULE__,)  unparsed_tag(node, pntd, reg1)
    @test_opt target_modules=(@__MODULE__,) function_filter=pff PnmlLabel(u)
    @test_opt target_modules=(@__MODULE__,) function_filter=pff anyelement(node, pntd, reg2)

    @test_call ignored_modules=(JET.AnyFrameModule(EzXML),
                                JET.AnyFrameModule(XMLDict)) unparsed_tag(node, pntd, reg1)
    @test_call ignored_modules=(JET.AnyFrameModule(EzXML),
                                JET.AnyFrameModule(XMLDict)) PnmlLabel(u)
    @test_call ignored_modules=(JET.AnyFrameModule(EzXML),
                                JET.AnyFrameModule(XMLDict)) anyelement(node, pntd, reg2)

    nn = Symbol(EzXML. nodename(node))
    @test haskey(u, nodename(node))
    @test tag(l) === nn
    @test tag(a) === nn

    @test u[nodename(node)] isa DictType
    @test l.elements isa DictType
    @test a.elements isa DictType
    #! unclaimed id is not registered
    haskey(u[nodename(node)], :id) && @test !isregistered(reg1, u[nodename(node)][:id])
    return l, a
end

@testset "unclaimed $pntd" for pntd in all_nettypes()
    noisy && println("## test unclaimed, PnmlLabel, anyelement")
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
        expected_label = PnmlLabel(expected)
        @test tag(lab) == tag(expected_label)
        @test (length ∘ elements)(lab) == ( length ∘ elements)(expected_label)
        # TODO recursive compare
        expected_any = AnyElement(expected)
        @test tag(anye) == tag(expected_any)
        @test (length ∘ elements)(anye) == (length ∘ elements)(expected_any)
        # TODO recursive compare
        noisy && println("-------------------")
    end
    noisy && println()
end
