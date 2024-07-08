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
    @test PNML.text(n) == ""; ids=(:NN,)

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
    empty!(PNML.TOPDECLDICTIONARY)
    dd = PNML.TOPDECLDICTIONARY[:nothing] = PNML.DeclDict()
    PNML.fill_nonhl!(dd; ids=(:nothing,))
    #@show pntd marking_value_type(pntd) dd
    #~ pntd -> user sort by markng_value_type
    placetype = SortType("test",
        UserSort(PNML.sorttag(marking_value_type(pntd)); ids=(:nothing,)))

    # Parse ignoring unexpected child
    mark = @test_logs((:warn, r"^ignoring unexpected child"),
                parse_initialMarking(node, placetype, pntd; ids=(:nothing,)))
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
    empty!(PNML.TOPDECLDICTIONARY)
    dd = PNML.TOPDECLDICTIONARY[:nothing] = PNML.DeclDict()
    #dd.namedsorts[:dot] = NamedSort(:dot, "Dot", DotSort(); ids)

    inscript = @test_logs((:warn, r"^ignoring unexpected child of <inscription>: 'unknown'"),
                            parse_inscription(n1, :nothing, :nothing, pntd; ids=(:NN,)))
    @test inscript isa PNML.Inscription
    @test typeof(value(inscript)) <: Union{Int,Float64}
    @test inscript() == value(inscript) == 12
    @test graphics(inscript) !== nothing
    @test tools(inscript) === nothing || !isempty(tools(inscript))
    @test_throws MethodError labels(inscript)

    @test occursin("Graphics", sprint(show, inscript))
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

        lab = add_label!(lab, node, pntd)
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
    @with PNML.idregistry => reg2 begin
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

@testset "type $pntd" for pntd in all_nettypes(ishighlevel)
    # Add usersort
    empty!(PNML.TOPDECLDICTIONARY)
    dd = PNML.TOPDECLDICTIONARY[:NN] = PNML.DeclDict()
    dd.namedsorts[:N2] = PNML.NamedSort(:N2, "N2", DotSort(); ids=(:NN,))
    dd.namedsorts[:dot] = NamedSort(:dot, "Dot", DotSort(); ids=(:NN,))
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
    #println()
    typ = PNML.parse_type(n1, pntd; ids=(:NN,))::SortType
    #@show text(typ) value(typ) sortof(typ) typeof(value(typ))
    #@test_logs (:warn,"ignoring unexpected child of <type>: 'unknown'")
    @test text(typ) == "N2"
    @test value(typ) isa UserSort # wrapping DotSort
    @test sortof(typ) == sortof(value(typ)) == DotSort() #! does the name of a sort affect equalSorts?
    #!@test declaration(value(typ)) == :N2
    @test PNML.has_graphics(typ) == true
    @test PNML.has_labels(typ) == false
    @test occursin("Graphics", sprint(show, typ))

    #@show PNML.SortType(value(typ)) #! does not propagate name?
    #@test value(PNML.SortType(value(typ))) isa PNML.UserSort
    #@test text(PNML.SortType(value(typ))) == ""
    #@test value(PNML.SortType("goofy", value(typ))) isa PNML.UserSort
    #@test text(PNML.SortType("goofy", value(typ))) == "goofy"
end

@testset "HL initMarking" begin

    @testset "3`dot $pntd" for pntd in all_nettypes(ishighlevel)
        println("\n3`dot $pntd")
        node = xml"""
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
        # Use the first part of this pair in contexts that want numbers.

        empty!(PNML.TOPDECLDICTIONARY)
        dd = PNML.TOPDECLDICTIONARY[:nothing] = PNML.DeclDict()
        dd.namedsorts[:dot] = NamedSort(:dot, "Dot", DotSort(); ids=(:nothing,))
        #@show dd
        # Marking is a multiset in high-level nets with sort matching placetype, :dot.
        placetype = SortType("test", UserSort(:dot; ids=(:nothing,)))

        mark = PNML.parse_hlinitialMarking(node, placetype, pntd; ids=(:nothing,))
        @test mark isa PNML.marking_type(pntd)
        #pprint(mark)

        @test value(mark) isa PNML.AbstractTerm
        @test text(mark) == "3`dot"

        @test PNML.has_graphics(mark) == false # This instance does not have any graphics.
        @test PNML.has_labels(mark) == false # Labels do not themselves have `Labels`, but you may ask.

        markterm = value(mark)
        @test markterm isa PNML.PnmlMultiset{<:Any, <:AbstractSort} # pnml many-sorted operator -> multiset
        # @test arity(markterm) == 2
        # @test inputs(markterm)[1] == NumberConstant(3, PositiveSort())
        # @test inputs(markterm)[2] == DotConstant()

        #TODO HL implementation not complete:
        #TODO  evaluate the HL expression, check place sorttype
    end


    @testset "useroperator" for pntd in all_nettypes(ishighlevel)
        println("\nuseroperator $pntd")
        node = xml"""
        <hlinitialMarking>
            <text>useroperator</text>
            <structure>
                <useroperator declaration="uop"/>
            </structure>
        </hlinitialMarking>
        """
        empty!(PNML.TOPDECLDICTIONARY)
        dd = PNML.TOPDECLDICTIONARY[:NN] = PNML.DeclDict()
        dd.namedsorts[:dot] = NamedSort(:dot, "Dot", DotSort(); ids=(:NN,))
        dd.namedoperators[:uop] = PNML.NamedOperator(:uop, "uop"; ids=(:NN,))
        dd.usersorts[:uop] = UserSort(:dot; ids=(:NN,))

        placetype = SortType("test", dd.usersorts[:uop])

        mark = PNML.parse_hlinitialMarking(node, placetype, pntd; ids=(:NN,))
        #@show value(mark)
        #pprint(mark)
    end

    # add two multisets: another way to express 3 + 2
    @testset "1`3 ++ 1`2" for pntd in all_nettypes(ishighlevel)
        println("\n1`3 ++ 1`2 $pntd")
        #~ @show
        node = xml"""
        <hlinitialMarking>
            <text>1`3 ++ 1`2</text>
            <structure>
                <add>
                    <subterm>
                        <numberof>
                        <subterm><dotconstant/></subterm>
                        <subterm><numberconstant value="3"><positive/></numberconstant></subterm>
                        </numberof>
                    </subterm>
                    <subterm>
                        <numberof>
                        <subterm><dotconstant/></subterm>
                        <subterm><numberconstant value="2"><positive/></numberconstant></subterm>
                        </numberof>
                    </subterm>
                </add>
            </structure>
        </hlinitialMarking>
        """
        empty!(PNML.TOPDECLDICTIONARY)
        dd = PNML.TOPDECLDICTIONARY[:NN] = PNML.DeclDict()
        dd.namedsorts[:dot] = NamedSort(:dot, "Dot", DotSort(); ids=(:NN,))
        dd.usersorts[:uop] = UserSort(:dot; ids=(:NN,))

        placetype = SortType("test", UserSort(:dot; ids=(:NN,)))

        mark = PNML.parse_hlinitialMarking(node, placetype, pntd; ids=(:NN,))
        #@show mark
        #pprint(mark)
    end

    # The constant eight.
    @testset "1`8" for pntd in all_nettypes(ishighlevel)
        println("\n1`8 $pntd")
        #~ @show
        node = xml"""
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
        empty!(PNML.TOPDECLDICTIONARY)
        dd = PNML.TOPDECLDICTIONARY[:NN] = PNML.DeclDict()
        dd.namedsorts[:dot] = NamedSort(:dot, "Dot", DotSort(); ids=(:NN,))
        dd.namedsorts[:pos] = NamedSort(:pos, "Positive", PositiveSort(); ids=(:NN,))

        placetype = SortType("test", UserSort(:pos; ids=(:NN,)))

        mark = PNML.parse_hlinitialMarking(node, placetype, pntd; ids=(:NN,))
        val = value(mark)::PNML.PnmlMultiset{<:Any, <:AbstractSort}
        @test PNML.basis(val) isa PositiveSort
        #@show val.mset
        #@show PNML.basis(val)
        #@show PNML.multiplicity(val, NumberConstant{Int64, PositiveSort}(8, PositiveSort()))

        @test PNML.multiplicity(val, NumberConstant{Int64, PositiveSort}(8, PositiveSort())) == 1
        @test PNML.sortof(PNML.basis(val)) === PNML.positivesort
        @test NumberConstant{Int64, PositiveSort}(8, PositiveSort()) in val.mset
     end

    # This is the same as when the element is omitted.
    @testset "x" for pntd in all_nettypes(ishighlevel)
        #println("\nomitted $pntd")
        node = xml"""
        <hlinitialMarking>
        </hlinitialMarking>
        """
        empty!(PNML.TOPDECLDICTIONARY)
        dd = PNML.TOPDECLDICTIONARY[:NN] = PNML.DeclDict()
        dd.namedsorts[:dot] = NamedSort(:dot, "Dot", DotSort(); ids=(:NN,))

        placetype = SortType("test", UserSort(:dot; ids=(:NN,)))

        mark = PNML.parse_hlinitialMarking(node, placetype, pntd; ids=(:NN,))
        #@show mark
        #@show value(mark)
    end

    println()
end





# @testset "<All,All>" for pntd in all_nettypes(ishighlevel)
#     println("\n<All,All> $pntd")
#     # <All,All> example from Sudoku-COL-A-N01.pnml
#     #~ YES, markings can be tuples, an operator, cries for TermInterface,Metatheory
#     #
#     node = xml"""
#     <hlinitialMarking>
#         <text>&lt;All,All&gt;</text>
#         <structure>
#             <tuple>
#                 <subterm><all><usersort declaration="N1"/></all></subterm>
#                 <subterm><all><usersort declaration="N2"/></all></subterm>
#             </tuple>
#         </structure>
#         <graphics><offset x="0" y="0"/></graphics>
#         <toolspecific tool="unknowntool" version="1.0"><atool x="0"/></toolspecific>
#         <unknown id="unkn">
#             <name> <text>unknown label</text> </name>
#             <text>content text</text>
#         </unknown>
#     </hlinitialMarking>
#  """

#     empty!(PNML.TOPDECLDICTIONARY)
#     dd = PNML.TOPDECLDICTIONARY[:NN] = PNML.DeclDict()
#     dd.namedsorts[:dot] = NamedSort(:dot, "Dot", DotSort(); ids=(:NN,))
#     dd.namedsorts[:N1]  = NamedSort(:N1, "N1", DotSort(); ids=(:NN,))
#     dd.namedsorts[:N2]  = NamedSort(:N2, "N2", DotSort(); ids=(:NN,))

#     @show placetype = SortType("test", TupleSort(UserSort[UserSort(:dot; ids=(:NN,)),
#                                                           UserSort(:dot; ids=(:NN,))]))

#     mark = PNML.parse_hlinitialMarking(node, placetype, pntd; ids=(:NN,))

#     #@test_logs(match_mode=:all, (:warn, "ignoring unexpected child of <hlinitialMarking>: 'unknown'"),
#     @test mark isa PNML.AbstractLabel
#     @test mark isa PNML.marking_type(pntd) #HLMarking
#     @test PNML.has_graphics(mark) == true
#     @test occursin("Graphics", sprint(show, mark))
#     @test PNML.has_labels(mark) == false

#     # Following HL text,structure label pattern where structure is a `Term`.
#     @test text(mark) == "<All,All>"
#     markterm = value(mark)
#     #~ @show markterm
#     @test markterm isa PNML.AbstractTerm
#     @test markterm isa PNML.Operator
#     @test tag(markterm) === :tuple # pnml many-sorted algebra's tuple

#     @test arity(markterm) == 2
#     #~ @show inputs(markterm)[1:1]
#     # # Decend each element of the term.
#     # @test tag(axn) == "subterm"
#     # @test value(axn) isa Vector #!{DictType}

#     # all1 = value(axn)[1]
#     # @test tag(all1) == "all"
#     # @test value(all1) isa DictType
#     # use1 = value(all1)["usersort"]
#     # @test use1 isa DictType
#     # @test use1[:declaration] == "N1"
#     # @test PNML._attribute(use1, :declaration) == "N1"

#     # all2 = value(axn)[2]
#     # @test tag(all2) == "all"
#     # @test value(all2) isa DictType
#     # use2 = value(all2)["usersort"]
#     # @test use2 isa DictType
#     # @test use2[:declaration] == "N2"
#     # @test PNML._attribute(use2, :declaration) == "N2"
# end

# @testset "hlinscription $pntd" for pntd in all_nettypes(ishighlevel)
#     println("\nhlinscription $pntd")
#     n1 = xml"""
#     <hlinscription>
#         <text>&lt;x,v&gt;</text>
#         <structure>
#             <tuple>
#               <subterm><variable refvariable="x"/></subterm>
#               <subterm><variable refvariable="v"/></subterm>
#             </tuple>
#         </structure>
#         <graphics><offset x="0" y="0"/></graphics>
#         <toolspecific tool="unknowntool" version="1.0"><atool x="0"/></toolspecific>
#         <unknown id="unkn">
#             <name> <text>unknown label</text> </name>
#             <text>content text</text>
#         </unknown>
#       </hlinscription>
#     """
#     empty!(PNML.TOPDECLDICTIONARY)
#     dd = PNML.TOPDECLDICTIONARY[:NN] = PNML.DeclDict()
#     dd.variabledecls[:x] = PNML.VariableDeclaration(:x, "", DotSort())
#     dd.variabledecls[:v] = PNML.VariableDeclaration(:v, "", DotSort())
#     @show placetype = SortType("test", UserSort(:dot; ids=(:nothing,)))


#     #@show PNML.TOPDECLDICTIONARY
#     insc = @test_logs(match_mode=:all,
#             (:warn,"ignoring unexpected child of <hlinscription>: 'unknown'"),
#             PNML.parse_hlinscription(n1, pntd; ids=(:NN,)))

#     @test typeof(insc) <: PNML.AbstractLabel
#     @test typeof(insc) <: PNML.inscription_type(pntd)
#     @test PNML.has_graphics(insc) == true
#     @test PNML.has_labels(insc) == false # Labels do not have sub-labels.

#     @test text(insc) isa Union{Nothing,AbstractString}
#     @test text(insc) == "<x,v>"

#     @test occursin("Graphics", sprint(show, insc))

#     #@show value(insc)
#     inscterm = value(insc)
#     @test inscterm isa PNML.AbstractTerm
#     @test tag(inscterm) === :tuple
#     @test arity(inscterm) == 2
#     @test inputs(inscterm)[1] isa PNML.Variable
#     @test inputs(inscterm)[2] isa PNML.Variable
#     @test tag(inputs(inscterm)[1]) == :x
#     @test tag(inputs(inscterm)[2]) == :v
#     #@test value(inputs(inscterm)[1]) Needs DeclDict
#     #@test value(inputs(inscterm)[2]) Needs DeclDict
# end

# @testset "structure $pntd" for pntd in all_nettypes(ishighlevel)
#     node = xml"""
#      <structure>
#         <tuple>
#             <subterm><all><usersort declaration="N1"/></all></subterm>
#             <subterm><all><usersort declaration="N2"/></all></subterm>
#         </tuple>
#      </structure>
#     """
#     # expected structure: tuple -> subterm -> all -> usersort -> declaration

#     stru = PNML.parse_structure(node, pntd; ids=(:NN,))
#     @test stru isa PNML.Structure
#     @test tag(stru) == :structure
#     axn = elements(stru)
#     @test axn isa DictType

#     tup = axn["tuple"]
#     sub = tup["subterm"]
#     #--------
#     all1 = sub[1]["all"]
#     usr1 = all1["usersort"]
#     @test value(usr1) == "N1"
#     @test value(axn["tuple"]["subterm"][1]["all"]["usersort"]) == "N1"
#     #--------
#     all2 = sub[2]["all"]
#     usr2 = all2["usersort"]
#     @test value(usr2) == "N2"
#     @test value(axn["tuple"]["subterm"][2]["all"]["usersort"]) == "N2"
# end



#! Setting up TOPDECLDICTIONARY is not worth the hassel
# # Conditions are for everybody, but we cannot (feasibily) test high-level
# @testset "condition $pntd" for pntd in all_nettypes(ishighlevel)
#     n1 = xml"""
#  <condition>
#     <text>pt==cts||pt==ack</text>
#     <structure>
#         <or>
#             <subterm>
#                 <equality>
#                     <subterm><variable refvariable="pt"/></subterm>
#                     <subterm><useroperator declaration="cts"/></subterm>
#                 </equality>
#             </subterm>
#             <subterm>
#                 <equality>
#                     <subterm><variable refvariable="pt"/></subterm>
#                     <subterm><useroperator declaration="ack"/></subterm>
#                 </equality>
#             </subterm>
#         </or>
#     </structure>
#     <graphics><offset x="0" y="0"/></graphics>
#     <toolspecific tool="unknowntool" version="1.0"><atool x="0"/></toolspecific>
#     <unknown id="unkn">
#         <name> <text>unknown label</text> </name>
#         <text>content text</text>
#     </unknown>
#  </condition>
#     """
#     @testset for node in [n1]
#         dd = PNML.DeclDict()
#         # dd.variabledecls[:pt] = PNML.VariableDeclaration(:pt, "", DotSort())
#         # dd.namedoperators[:cts] = PNML.NamedOperator(:cts, "", [], nothing)
#         # dd.namedoperators[:ack] = PNML.NamedOperator(:ack, "", [], nothing)
#         # PNML.TOPDECLDICTIONARY[:NN] = dd

#         cond = @test_logs(match_mode=:all,
#                 (:warn, "ignoring unexpected child of <condition>: 'unknown'"),
#                 PNML.parse_condition(node, pntd; ids=(:NN,)))
#         @test cond isa PNML.condition_type(pntd)
#         @show cond
#         @test text(cond) == "pt==cts||pt==ack"
#         # @test value(cond) isa PNML.Operator #!Union{PNML.condition_value_type(pntd), PNML.Term} Boolean operator
#         # @test tag(value(cond)) == :or
#         @test PNML.has_graphics(cond) == true
#         @test PNML.has_labels(cond) == false
#     end
# end
