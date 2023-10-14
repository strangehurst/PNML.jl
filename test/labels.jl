using PNML, EzXML, ..TestUtils, JET, PrettyPrinting, NamedTupleTools, AbstractTrees
#using FunctionWrappers
using PNML:
    Maybe, tag, XMLNode, xmlroot, labels,
    unparsed_tag, anyelement, PnmlLabel, AnyElement,
    has_label, get_label, get_labels, add_label!,
    default_marking, default_inscription, default_condition, default_sort,
    default_one_term, default_zero_term,
    has_graphics, graphics, has_name, name, has_label,
    value, tools, graphics, labels,
    parse_initialMarking, parse_inscription, parse_text,
    elements, all_nettypes, ishighlevel


@testset "text $pntd" for pntd in all_nettypes()
    @test parse_text(xml"<text>ready</text>", pntd, registry()) == "ready"
end

#=
@testset "ObjectCommon $pntd" for pntd in all_nettypes()
    oc = @inferred PNML.ObjectCommon()

    @test isnothing(PNML.graphics(oc))
    @test isempty(PNML.tools(oc))
    @test isempty(PNML.labels(oc))

    oc = @inferred PNML.ObjectCommon(nothing, PNML.ToolInfo[], PNML.PnmlLabel[])
    @test isnothing(PNML.graphics(oc))
    @test isempty(PNML.tools(oc))
    @test isempty(PNML.labels(oc))
end
=#
#------------------------------------------------
@testset "name $pntd" for pntd in all_nettypes()
    n = @test_logs (:warn, r"^<name> missing <text>") PNML.parse_name(xml"<name></name>", pntd, registry())
    @test n isa PNML.AbstractLabel
    #println("dump n"); dump(n)
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
    # Parse
    mark = @test_logs (:warn, "<initialMarking> ignoring unknown child 'unknown'") parse_initialMarking(node, pntd, registry())
    @test mark isa PNML.Marking
    @test typeof(value(mark)) <: Union{Int,Float64}
    @test value(mark) == mark() == 123
    Base.redirect_stdio(stdout=testshow, stderr=testshow) do
        @show mark
    end

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
    Base.redirect_stdio(stdout=testshow, stderr=testshow) do
        @show inscript
    end
    @test inscript() == value(inscript) == 12
    @test graphics(inscript) !== nothing
    @test tools(inscript) === nothing || !isempty(tools(inscript))
    @test_throws ErrorException labels(inscript) # === nothing || !isempty(labels(inscript))
end

@testset "labels $pntd" for pntd in all_nettypes()
    lab = PnmlLabel[]
    reg = registry()

    for i in 1:4 # create & add 4 labels
        x = i < 3 ? 1 : 2 # make 2 different tagnames
        node = xmlroot("<test$x> $i </test$x>")::XMLNode
        @test_call  ignored_modules=(JET.AnyFrameModule(EzXML),) add_label!(lab, node, pntd, reg)
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
    @test elements(v) isa Vector
    @test tag(elements(v)[1]) === :content
    @test value(elements(v)[1]) == "3"

    @testset "label $labeltag" for labeltag in [:test1, :test2]
        v = PNML.get_labels(lab, labeltag)
        lv = 0
        for l in v
            @test tag(l) === labeltag
            lv += 1
        end
        @test lv == 2
    end
end

@testset "unclaimed structure $pntd" for pntd in all_nettypes()
    str0 = """<structure><foo/></structure>"""
    @test PNML.parse_node(xmlroot(str0), pntd, registry()) isa PNML.Structure
end

@testset "<label> $pntd" for pntd in all_nettypes()
    str0 = """<label><text>label named label is unusual</text></label>"""
    l = PNML.parse_node(xmlroot(str0), pntd, registry())
    @test l isa @NamedTuple{tag::Symbol,xml::XMLNode}
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

    u = unparsed_tag(node, pntd)
    l = PnmlLabel(u)
    a = anyelement(node, pntd, reg2)
    if noisy
        println("u = $(u.first) "); dump(u)
        println("l = $(l.tag) ");   dump(l)
        println("a = $(a.tag) " );  dump(a)
    end
    @test u isa Pair{Symbol, Vector{PNML.AnyXmlNode}}
    @test l isa PnmlLabel
    @test a isa AnyElement
    Base.redirect_stdio(stdout=testshow, stderr=testshow) do
        @show u l a [a]
    end

    @test_opt target_modules=(@__MODULE__,)  unparsed_tag(node, pntd, reg1)
    @test_opt function_filter=pff PnmlLabel(u)
    @test_opt target_modules=(@__MODULE__,) function_filter=pff anyelement(node, pntd, reg2)

    @test_call unparsed_tag(node, pntd, reg1)
    @test_call PnmlLabel(u)
    @test_call anyelement(node, pntd, reg2)

    let nn = Symbol(EzXML. nodename(node))
        @test u.first === nn
        @test tag(l) === nn
        @test tag(a) === nn
    end
    @test u.second isa Vector{PNML.AnyXmlNode}
    @test l.elements isa Vector{PNML.AnyXmlNode}
    @test a.elements isa Vector{PNML.AnyXmlNode}
    #! unclaimed id is not registered
    u.second[1].tag === :id && @test !isregistered(reg1, u.second[1].val)
    return l, a
end

@testset "unclaimed $pntd" for pntd in all_nettypes()
    noisy && println("## test unclaimed, PnmlLabel, anyelement")
    # Even though they are "claimed" by having a parser, they still may be treated as unclaimed.
    # For example <declarations>.
    ctrl = [ # Vector of tuples of XML string, expected result `Pair`.
        ("""<declarations> </declarations>""",
            :declarations => PNML.AnyXmlNode[PNML.AnyXmlNode(:content, "")]),

        ("""<declarations atag="atag1"> </declarations>""",
            :declarations => PNML.AnyXmlNode[PNML.AnyXmlNode(:atag, "atag1")]),

        ("""<foo><declarations> </declarations></foo>""",
            :foo => PNML.AnyXmlNode[PNML.AnyXmlNode(:declarations, PNML.AnyXmlNode[PNML.AnyXmlNode(:content, "")])]),

        # no content, no attribute maybe results in empty tuple.
        ("""<null></null>""",
            :null => PNML.AnyXmlNode[PNML.AnyXmlNode(:content, "")]),
        ("""<null2/>""",
            :null2 => PNML.AnyXmlNode[PNML.AnyXmlNode(:content, "")]),
        # no content, with attribute
        ("""<null at="null"></null>""",
            :null => PNML.AnyXmlNode[PNML.AnyXmlNode(:at, "null")]),
        ("""<null2 at="null2" />""",
            :null2 => PNML.AnyXmlNode[PNML.AnyXmlNode(:at, "null2")]),
        # empty content, no attribute
        ("""<empty> </empty>""",
            :empty => PNML.AnyXmlNode[PNML.AnyXmlNode(:content, "")]),
        # empty content, with attribute
        ("""<empty at="empty"> </empty>""",
            :empty => PNML.AnyXmlNode[PNML.AnyXmlNode(:at, "empty")]),
        # unclaimed do not register id
        ("""<foo id="testid1" />""",
            :foo => PNML.AnyXmlNode[PNML.AnyXmlNode(:id, "testid1")]),
        ("""<foo id="testid2"/>""",
            :foo => PNML.AnyXmlNode[PNML.AnyXmlNode(:id, "testid2")]),

        ("""<foo id="repeats">
                <one>ONE</one>
                <one>TWO</one>
                <one>TRI</one>
            </foo>""",
            :foo => PNML.AnyXmlNode[PNML.AnyXmlNode(:id, "repeats"),
                                    PNML.AnyXmlNode(:one, PNML.AnyXmlNode[PNML.AnyXmlNode(:content, "ONE")]),
                                    PNML.AnyXmlNode(:one, PNML.AnyXmlNode[PNML.AnyXmlNode(:content, "TWO")]),
                                    PNML.AnyXmlNode(:one, PNML.AnyXmlNode[PNML.AnyXmlNode(:content, "TRI")])]),

        ("""<declarations atag="atag2">
                <something> some content </something>
                <something> other stuff </something>
                <something2 tag2="tagtwo"> <value/> <value tag3="tagthree"/> </something2>
            </declarations>""",
            :declarations => PNML.AnyXmlNode[
                        PNML.AnyXmlNode(:atag, "atag2"),
                        PNML.AnyXmlNode(:something, PNML.AnyXmlNode[PNML.AnyXmlNode(:content, "some content")]),
                        PNML.AnyXmlNode(:something, PNML.AnyXmlNode[PNML.AnyXmlNode(:content, "other stuff")]),
                        PNML.AnyXmlNode(:something2, PNML.AnyXmlNode[PNML.AnyXmlNode(:tag2, "tagtwo"),
                                                    PNML.AnyXmlNode(:value, PNML.AnyXmlNode[PNML.AnyXmlNode(:content, "")]),
                                                    PNML.AnyXmlNode(:value, PNML.AnyXmlNode[PNML.AnyXmlNode(:tag3, "tagthree")])])
                                            ]),
    ]

    for (s, expected) in ctrl
        lab, anye = test_unclaimed(pntd, s)
        # TODO Add equality test, skip xml node.
        expected_label = PnmlLabel(expected)
        #@show lab expected_label
        @test tag(lab) == tag(expected_label)
        @test (length ∘ elements)(lab) == ( length ∘ elements)(expected_label)
        # TODO recursive compare
        expected_any = AnyElement(expected)
        #@show anye  expected_any
        @test tag(anye) == tag(expected_any)
        @test (length ∘ elements)(anye) == (length ∘ elements)(expected_any)
        # TODO recursive compare
        noisy && println("-------------------")
    end
    noisy && println()
end
