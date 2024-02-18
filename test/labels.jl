using PNML, EzXML, XMLDict, ..TestUtils, JET, NamedTupleTools, AbstractTrees

using PNML:
    Maybe, tag, XMLNode, xmlroot, unparsed_tag, anyelement, PnmlLabel, AnyElement,
    has_label, get_label, get_labels, add_label!, labels,
    default_marking, default_inscription, default_condition, default_sort,
    default_one_term, default_zero_term,
    has_graphics, graphics, has_name, name,
    parse_initialMarking, parse_inscription, parse_text,
    tag, pid, text, value, tools, elements, all_nettypes, ishighlevel,
    DictType, XDVT

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
    @test_opt PNML.Marking(3.5)
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
    inscript = @test_logs (:warn, "ignoring unexpected child of <inscription>: 'unknown'") parse_inscription(n1, pntd, registry())
    @test inscript isa PNML.Inscription
    @test typeof(value(inscript)) <: Union{Int,Float64}
    @test inscript() == value(inscript) == 12
    @test graphics(inscript) !== nothing
    @test tools(inscript) === nothing || !isempty(tools(inscript))
    @test_throws MethodError labels(inscript)

    @test occursin("Graphics", sprint(show, inscript))
end

FF(@nospecialize f) = f !== EZXML.throw_xml_error;

@testset "add_labels JET $pntd" for pntd in all_nettypes()
    # lab = PnmlLabel[]
    # reg = registry()
    # @show pff(PNML.add_label!) pff(PNML.unparsed_tag) pff(PNML.labels)
    # @test_opt add_label!(lab, node, pntd, reg)
    # @test_opt(broken=false,
    #             ignored_modules=(JET.AnyFrameModule(EzXML),
    #                             JET.AnyFrameModule(XMLDict),
    #                             JET.AnyFrameModule(Base.CoreLogging)),
    #             function_filter=pff,
    #             add_label!(lab, xml"""<test1> 1 </test1>""", pntd, reg))

    # @test_call add_label!(lab, node, pntd, reg)
    # @test_call(ignored_modules=(JET.AnyFrameModule(EzXML),
    #                             JET.AnyFrameModule(XMLDict)),
    #                             add_label!(lab, node, pntd, reg))
end

@testset "labels $pntd" for pntd in all_nettypes()
    lab = PnmlLabel[]
    reg = registry()
    for i in 1:4 # create & add 4 labels
        x = i < 3 ? 1 : 2 # make 2 different tagnames
        node = xmlroot("<test$x> $i </test$x>")::XMLNode

        @test add_label!(lab, node, pntd, reg) isa PnmlLabel
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
    if noisy
        println("+++++++++++++++++++")
        println("XML: ", xmlstring)
        println("-------------------")
    end
    node::XMLNode = xmlroot(xmlstring)
    reg1 = registry() # Need 2 test registries to ensure any ids do not collide.
    reg2 = registry() # Creating multiple things from the same string is not recommended.

    xdict = XMLDict.xml_dict(node, PNML.DictType)

    (t,u) = unparsed_tag(node, pntd) # tag is a string
    l = PnmlLabel(t, u)
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
    @test_opt target_modules=(@__MODULE__,) function_filter=pff PnmlLabel(t,u)
    @test_opt target_modules=(@__MODULE__,) function_filter=pff anyelement(node, pntd, reg2)

    @test_call ignored_modules=(JET.AnyFrameModule(EzXML),
                                JET.AnyFrameModule(XMLDict)) unparsed_tag(node, pntd, reg1)
    @test_call ignored_modules=(JET.AnyFrameModule(EzXML),
                                JET.AnyFrameModule(XMLDict)) PnmlLabel(t,u)
    @test_call ignored_modules=(JET.AnyFrameModule(EzXML),
                                JET.AnyFrameModule(XMLDict)) anyelement(node, pntd, reg2)

    nn = Symbol(EzXML. nodename(node))
    @test t == nodename(node)
    @test tag(l) === nn
    @test tag(a) === nn

    @test u isa DictType
    @test l.elements isa DictType
    @test a.elements isa DictType
    #! unclaimed id is not registered
    x = get(u, :id, nothing)
    !isnothing(x) && @test !isregistered(reg1, x) #u[:id])
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
        expected_label = PnmlLabel(expected...)
        @test tag(lab) == tag(expected_label)
        @test (length ∘ elements)(lab) == ( length ∘ elements)(expected_label)
        # TODO recursive compare
        expected_any = AnyElement(expected...)
        @test tag(anye) == tag(expected_any)
        @test (length ∘ elements)(anye) == (length ∘ elements)(expected_any)
        # TODO recursive compare
        noisy && println("-------------------")
    end
    noisy && println()
end


@testset "HL initMarking $pntd" for pntd in all_nettypes(ishighlevel)

    @testset "3`dot" begin
        @show node = xml"""
        <hlinitialMarking>
            <text>3`dot</text>
            <structure>
                <numberof>
                    <subterm><numberconstant value="3"><positive/></numberconstant></subterm>
                    <subterm><dotconstant/></subterm>
                </numberof>
            </structure>
        </hlinitialMarking>
        """
        # numberof is an operator: natural number, element of a sort -> multiset
        # subterms are in an ordered collection, first is a number, second an element of a sort
        # Use the first part of this pair in contextes that want numbers.
        mark = @test_logs(match_mode=:all, PNML.parse_hlinitialMarking(node, pntd, registry()))
        @test mark isa PNML.marking_type(pntd)
        #pprint(mark)

        @test value(mark) isa PNML.AbstractTerm # Should be Variable or Operator
        @test text(mark) == "3`dot"

        @test PNML.has_graphics(mark) == false # This instance does not have any graphics.
        @test PNML.has_labels(mark) == false # Labels do not themselves have `Labels`, but you may ask.
        # Any `Label` children must be "well behaved xml".

        @show value(mark)
        @show mark()

        markterm = value(mark)
        @test tag(markterm) === :numberof # pnml many-sorted operator -> multiset
        parameters = elements(markterm)["subterm"]
        @test length(parameters) == 2
        @test parameters[1]["numberconstant"][:value] == "3"
        @test isempty(parameters[2]["dotconstant"])

        #TODO HL implementation not complete:
        #TODO  evaluate the HL expression, check place sorttype

        #@show axn #! debug
    end

    @testset "<All,All>" begin #! Does this Term make sense as a marking?
        @show node = xml"""
        <hlinitialMarking>
            <text>&lt;All,All&gt;</text>
            <structure>
                <tuple>
                    <subterm><all><usersort declaration="N1"/></all></subterm>
                    <subterm><all><usersort declaration="N2"/></all></subterm>
                </tuple>
            </structure>
            <graphics><offset x="0" y="0"/></graphics>
            <toolspecific tool="unknowntool" version="1.0"><atool x="0"/></toolspecific>
            <unknown id="unkn">
                <name> <text>unknown label</text> </name>
                <text>content text</text>
            </unknown>
        </hlinitialMarking>
        """
        mark = @test_logs(match_mode=:all, (:warn, "ignoring unexpected child of <hlinitialMarking>: 'unknown'"),
            PNML.parse_hlinitialMarking(node, pntd, registry()))

        @test mark isa PNML.AbstractLabel
        @test mark isa PNML.marking_type(pntd) #HLMarking
        #pprint(mark)
        @test occursin("Graphics", sprint(show, mark))

        # Following HL text,structure label pattern where structure is a `Term`.
        @test text(mark) == "<All,All>"
        @test value(mark) isa PNML.AbstractTerm
        @test value(mark) isa PNML.Term

        @test PNML.has_graphics(mark) == true
        @test PNML.has_labels(mark) == false

        @show value(mark)
        markterm = value(mark)
        @test tag(markterm) === :tuple # pnml many-sorted algebra's tuple

        axn = elements(markterm)

        # Decend each element of the term.
        @test tag(axn) == "subterm"
        @test value(axn) isa Vector #!{DictType}

        all1 = value(axn)[1]
        @test tag(all1) == "all"
        @test value(all1) isa DictType
        use1 = value(all1)["usersort"]
        @test use1 isa DictType
        @test use1[:declaration] == "N1"
        @test PNML._attribute(use1, :declaration) == "N1"

        all2 = value(axn)[2]
        @test tag(all2) == "all"
        @test value(all2) isa DictType
        use2 = value(all2)["usersort"]
        @test use2 isa DictType
        @test use2[:declaration] == "N2"
        @test PNML._attribute(use2, :declaration) == "N2"
    end

    @testset "useroperator" begin
        node = xml"""
        <hlinitialMarking>
            <text>useroperator</text>
            <structure>
                <useroperator declaration="id4"/>
            </structure>
        </hlinitialMarking>
        """
        mark = @test_logs(match_mode=:all, PNML.parse_hlinitialMarking(node, pntd, registry()))
        #@show value(mark)
        #pprint(mark)
    end

    # add two multisets: another way to express 3 + 2
    @testset "1`3 ++ 1`2" begin
        @show node = xml"""
        <hlinitialMarking>
            <text>1`3 ++ 1`2</text>
            <structure>
                <add>
                    <subterm>
                        <numberof>
                        <subterm><numberconstant value="1"><positive/></numberconstant></subterm>
                        <subterm><numberconstant value="3"><positive/></numberconstant></subterm>
                        </numberof>
                    </subterm>
                    <subterm>
                        <numberof>
                        <subterm><numberconstant value="1"><positive/></numberconstant></subterm>
                        <subterm><numberconstant value="2"><positive/></numberconstant></subterm>
                        </numberof>
                    </subterm>
                </add>
            </structure>
        </hlinitialMarking>
        """
        mark = @test_logs(match_mode=:all, PNML.parse_hlinitialMarking(node, pntd, registry()))
        #@show mark
        @show value(mark)
        #pprint(mark)
    end

    # The constant eight.
    @testset "1`8" begin
        @show node = xml"""
        <hlinitialMarking>
            <text>1`8</text>
            <structure>
                <numberof>
                <subterm><numberconstant value="1"><positive/></numberconstant></subterm>
                <subterm><numberconstant value="8"><positive/></numberconstant></subterm>
                </numberof>
            </structure>
        </hlinitialMarking>
        """
        mark = @test_logs(match_mode=:all, PNML.parse_hlinitialMarking(node, pntd, registry()))
        #@show mark
        @show value(mark)
        #pprint(mark)
    end

    # This is the same as when the element is omitted.
    @testset "x" begin
        node = xml"""
        <hlinitialMarking>
        </hlinitialMarking>
        """
        mark = @test_logs(match_mode=:all, PNML.parse_hlinitialMarking(node, pntd, registry()))
        #@show mark
        #@show value(mark)
        #pprint(mark)
    end

    println()
end

@testset "hlinscription $pntd" for pntd in all_nettypes(ishighlevel)
    n1 = xml"""
    <hlinscription>
        <text>&lt;x,v&gt;</text>
        <structure>
            <tuple>
              <subterm><variable refvariable="x"/></subterm>
              <subterm><variable refvariable="v"/></subterm>
            </tuple>
        </structure>
        <graphics><offset x="0" y="0"/></graphics>
        <toolspecific tool="unknowntool" version="1.0"><atool x="0"/></toolspecific>
        <unknown id="unkn">
            <name> <text>unknown label</text> </name>
            <text>content text</text>
        </unknown>
      </hlinscription>
    """
    insc = @test_logs(match_mode=:all, (:warn,"ignoring unexpected child of <hlinscription>: 'unknown'"),
            #(:info, "parse_term kinds are Variable and Operator"),
            PNML.parse_hlinscription(n1, pntd, registry()))

    @test typeof(insc) <: PNML.AbstractLabel
    @test typeof(insc) <: PNML.inscription_type(pntd)
    @test PNML.has_graphics(insc) == true
    @test PNML.has_labels(insc) == false

    @test text(insc) isa Union{Nothing,AbstractString}
    @test text(insc) == "<x,v>"

    @test occursin("Graphics", sprint(show, insc))

    #@show value(insc)
    inscterm = value(insc)
    @test inscterm isa PNML.Term
    @test tag(inscterm) === :tuple
    axn = elements(inscterm)

    #TODO HL implementation not complete:

    sub1 = axn["subterm"][1]
    @test tag(sub1) == "variable"
    var1 = PNML._attribute(sub1["variable"], :refvariable)
    @test var1 == "x"

    sub2 = axn["subterm"][2]
    @test tag(sub2) == "variable"
    var2 = PNML._attribute(sub2["variable"], :refvariable)
    @test var2 == "v"
end

@testset "structure $pntd" for pntd in all_nettypes(ishighlevel)
    node = xml"""
     <structure>
        <tuple>
            <subterm><all><usersort declaration="N1"/></all></subterm>
            <subterm><all><usersort declaration="N2"/></all></subterm>
        </tuple>
     </structure>
    """
    # expected structure: tuple -> subterm -> all -> usersort -> declaration

    stru = PNML.parse_structure(node, pntd, registry())
    @test stru isa PNML.Structure
    @test tag(stru) == :structure
    axn = elements(stru)
    @test axn isa DictType

    tup = axn["tuple"]
    sub = tup["subterm"]
    #--------
    all1 = sub[1]["all"]
    usr1 = all1["usersort"]
    @test value(usr1) == "N1"
    @test value(axn["tuple"]["subterm"][1]["all"]["usersort"]) == "N1"
    #--------
    all2 = sub[2]["all"]
    usr2 = all2["usersort"]
    @test value(usr2) == "N2"
    @test value(axn["tuple"]["subterm"][2]["all"]["usersort"]) == "N2"
end

@testset "type $pntd" for pntd in all_nettypes(ishighlevel)
    n1 = xml"""
<type>
    <text>N2</text>
    <structure> <usersort declaration="N2"/> </structure>
    <graphics><offset x="0" y="0"/></graphics>
    <toolspecific tool="unknowntool" version="1.0"><atool x="0"/></toolspecific>
    <unknown id="unkn">
        <name> <text>unknown label</text> </name>
        <text>content text</text>
    </unknown>
</type>
    """
    @testset for node in [n1]
        typ =  @test_logs (:warn,"ignoring unexpected child of <type>: 'unknown'") PNML.parse_type(node, pntd, registry())
        @test typ isa PNML.SortType
        @test text(typ) == "N2"
        @test value(typ) isa PNML.AbstractSort
        @test PNML.type(typ) == PNML.UserSort
        @test value(typ).declaration == :N2
        @test PNML.has_graphics(typ) == true
        @test PNML.has_labels(typ) == false
        @test occursin("Graphics", sprint(show, typ))

        @test value(PNML.SortType(value(typ))) isa PNML.UserSort
        @test text(PNML.SortType(value(typ))) == ""
        @test value(PNML.SortType("goofy", value(typ))) isa PNML.UserSort
        @test text(PNML.SortType("goofy", value(typ))) == "goofy"
    end
end

# conditions are for everybody.
@testset "condition $pntd" for pntd in all_nettypes()
    n1 = xml"""
 <condition>
    <text>(x==1 and y==1 and d==1)</text>
    <structure> <or> #TODO </or> </structure>
    <graphics><offset x="0" y="0"/></graphics>
    <toolspecific tool="unknowntool" version="1.0"><atool x="0"/></toolspecific>
    <unknown id="unkn">
        <name> <text>unknown label</text> </name>
        <text>content text</text>
    </unknown>
 </condition>
    """
    @testset for node in [n1]
        cond = @test_logs(match_mode=:all, (:warn, "ignoring unexpected child of <condition>: 'unknown'"),
                #(:info, "parse_term kinds are Variable and Operator"),
                PNML.parse_condition(node, pntd, registry()))
        @test cond isa PNML.condition_type(pntd)
        @test text(cond) == "(x==1 and y==1 and d==1)"
        @test value(cond) isa Union{PNML.condition_value_type(pntd), PNML.Term}
        @test tag(value(cond)) == :or
        @test PNML.has_graphics(cond) == true
        @test PNML.has_labels(cond) == false
    end
end
