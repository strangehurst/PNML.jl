using PNML, JET
include("TestUtils.jl")
using .TestUtils, NamedTupleTools, OrderedCollections
using EzXML: EzXML
using XMLDict: XMLDict

#------------------------------------------------
@testset "PT initMarking $pntd" for pntd in (PnmlCoreNet(), ContinuousNet())
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

    net = make_net(pntd, :pt_initmark)
    @show PNML.value_type(PNML.Marking, pntd)
    @show PNML.Labels.sortref(PNML.value_type(PNML.Marking, pntd))

    placetype = SortType("$pntd initMarking",
        PNML.sortref(PNML.value_type(PNML.Marking, pntd))::SortRef,
        nothing, nothing, net)

    # Parse ignoring unexpected child
    mark = @test_logs(match_mode=:any, (:warn, r"^ignoring unexpected child"),
                parse_initialMarking(node, placetype, pntd; net, parentid=:xxx)::PNML.Marking)
    #@test typeof(value(mark)) <: Union{Int,Float64}
    @test mark()::Union{Int,Float64} == 123

    # Integer
    mark1 = PNML.Marking(23, net)
    @test_opt broken=false PNML.Marking(23, net)
    @test_call PNML.Marking(23, net)
    @test typeof(mark1()) == typeof(23)
    @test mark1() == 23
    @test_opt broken=false mark1()
    @test_call mark1()

    @test graphics(mark1) === nothing
    @test toolinfos(mark1) === nothing || isempty(toolinfos(mark1))

    # Floating point
    mark2 = PNML.Marking(3.5, net)
    #@show mark2 mark2()
    @test_opt broken=false PNML.Marking(3.5, net)
    @test_call PNML.Marking(3.5, net)
    @test typeof(mark2()) == typeof(3.5)
    @test mark2() ≈ 3.5
    @test_call mark2()
    @test graphics(mark2) === nothing
    @test toolinfos(mark2) === nothing || isempty(toolinfos(mark2))
end

@testset "HL initMarking" begin
     @testset "3`dot $pntd" for pntd in PnmlTypes.all_nettypes(ishighlevel)
        #println("\n3`dot $pntd")
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
        # This is a high-level integer, use the first part of this pair in contexts that want numbers.
        net = make_net(pntd, :dot_net)
        # Marking is a multiset in high-level nets with sort matching placetype, :dot.
        placetype = SortType("XXX", PNML.NamedSortRef(:dot), net)

        mark = parse_hlinitialMarking(node, placetype, pntd; net, parentid=:bogusid)
        #@show mark
        @test mark isa PNML.Marking

        @test PNML.term(mark) isa PNML.Bag
        @test text(mark) == "3`dot"
        #println(); flush(stdout)

        @test PNML.has_graphics(mark) == false # This instance does not have any graphics.
        #@show term(mark) PNML.toexpr(term(mark), NamedTuple(), net) #! debug
        @test eval(PNML.toexpr(term(mark), NamedTuple(), net)) isa PNML.PnmlMultiset
        # @test arity(markterm) == 2
        # @test inputs(markterm)[1] == NumberConstant(3, PositiveSort())
        # @test inputs(markterm)[2] == DotConstant()

        #TODO HL implementation not complete:
        #TODO  evaluate the HL expression, check place sorttype
    end

    # 0-arity operators are constants
    # @testset "useroperator" for pntd in PnmlTypes.all_nettypes(ishighlevel)
    #     println("\nuseroperator $pntd")
    #     node = xml"""
    #     <hlinitialMarking>
    #         <text>useroperator</text>
    #         <structure>
    #             <useroperator declaration="uop"/>
    #         </structure>
    #     </hlinitialMarking>
    #     """
    #     @with PNML.idregistry => IDRegistry() begin
    #         PNML.namedoperators()[:uop] = PNML.NamedOperator(:uop, "uop")
    #         placetype = SortType("YYY", PNML.usersort(ddict, :uop))
    #         mark = parse_hlinitialMarking(node, placetype, pntd)
    #         @test mark isa Marking
    #     end
    # end


   @testset "placetype error" for pntd in PnmlTypes.all_nettypes(ishighlevel)
        #println("\nplacetype error")
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
        # This is a high-level integer, use the first part of this pair in contexts that want numbers.
        net = make_net(pntd, :placetype_error_net)
        sort = ArbitrarySort(:foo, "ArbSort", net)
        PNML.fill_sort_tag!(net, :foo, sort)

        # Marking is a multiset in high-level nets with sort matching placetype, :dot.
        # @show placetype = SortType("XXX", PNML.ArbitrarySortRef(:foo), ctx.ddict)

        # mark = parse_hlinitialMarking(node, placetype, pntd; net, parentid=:bogusid)
    end

    # add two multisets: another way to express 3 + 2
    @testset "3`dot ++ 2'dot" for pntd in PnmlTypes.all_nettypes(ishighlevel)
        #println("\n\"3'dot ++ 2'dot\" $pntd")
        #~ @show
        node = xml"""
        <hlinitialMarking>
            <text>3'dot ++ 2'dot</text>
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
        net = make_net(pntd, :dot_dot)
        placetype = SortType("dot sorttype", PNML.NamedSortRef(:dot), net)
        mark = PNML.Parser.parse_hlinitialMarking(node, placetype, pntd; net, parentid=:tmp)
        #TODO add tests
    end
    # The constant eight.
    @testset "1`8" for pntd in PnmlTypes.all_nettypes(ishighlevel)
        #println("\n1`8 $pntd")
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
        net = make_net(pntd, :dot_1)
        placetype = SortType("positive sorttype", PNML.NamedSortRef(:positive), net)
        mark = parse_hlinitialMarking(node, placetype, pntd; net, parentid=:xxx)
        val = eval(toexpr(term(mark), NamedTuple(), net))::PNML.PnmlMultiset
        @test PNML.multiplicity(val, NumberConstant(8, NamedSortRef(:positive))()) == 1
        @test NumberConstant(8, NamedSortRef(:positive))() in multiset(val)
     end

    # This is the same as when the element is omitted.
    @testset "x" for pntd in PnmlTypes.all_nettypes(ishighlevel)
        node = xml"""
        <hlinitialMarking>
        </hlinitialMarking>
        """
        net = make_net(pntd, :empty_hlinitialMarking)
        placetype = SortType("testdot", PNML.NamedSortRef(:dot), net)
        @test_throws Exception parse_hlinitialMarking(node, placetype, pntd; net, parentid=:xxx)
    end

    #println()
end

@testset "FIFO initMarking" begin

     @testset "FIFO $pntd" for pntd in PnmlTypes.all_nettypes(ishighlevel)
        #println("\n3`dot $pntd")
        node = xml"""
        <fifoinitialMarking>
            <text>FIFO(dot)</text>
            <structure>
                <makelist>
                    <dot/>
                    <subterm><dotconstant/></subterm>
                    <subterm><dotconstant/></subterm>
                    <subterm><dotconstant/></subterm>
                </makelist>
            </structure>
        </fifoinitialMarking>
        """
        # numberof is an operator: natural number, element of a sort -> multiset
        # subterms are in an ordered collection, first is a number, second an element of a sort
        # This is a high-level integer, use the first part of this pair in contexts that want numbers.

        net = make_net(pntd, :fifi_net)

        # Marking is a multiset in high-level nets with sort matching placetype, :dot.
        placetype = SortType("FIFO", PNML.NamedSortRef(:dot), net)

        mark = parse_fifoinitialMarking(node, placetype, pntd; net, parentid=:bogusid)
        #@show mark
        @test mark isa PNML.Marking

        #@test PNML.term(mark) isa PNML.Bag
        #@test text(mark) == "3`dot"
        #println(); flush(stdout)

        @test PNML.has_graphics(mark) == false # This instance does not have any graphics.
        #@show term(mark) PNML.toexpr(term(mark), NamedTuple(), net) #! debug
        @test eval(PNML.toexpr(term(mark), NamedTuple(), net)) isa Vector{PNML.DotConstant}
        # @test arity(markterm) == 2
        # @test inputs(markterm)[1] == NumberConstant(3, PositiveSort())
        # @test inputs(markterm)[2] == DotConstant()
    end
end # fifoinitialMarking


# @testset "<All,All>" for pntd in PnmlTypes.all_nettypes(ishighlevel)
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

#     dd.namedsorts[:dot] = NamedSort(:dot, "Dot", DotSort())
#     dd.namedsorts[:N1]  = NamedSort(:N1, "N1", DotSort())
#     dd.namedsorts[:N2]  = NamedSort(:N2, "N2", DotSort())

#     mark = PNML.parse_hlinitialMarking(node, placetype, pntd)

#     #@test_logs(match_mode=:all, (:warn, "ignoring unexpected child of <hlinitialMarking>: 'unknown'"),
#     @test mark isa PNML.AbstractLabel
#     @test mark isa PNML.Marking
#     @test PNML.has_graphics(mark) == true
#     @test occursin("Graphics", sprint(show, mark))

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
#     # @test value(axn) isa Vector #!{XmlDictType}

#     # all1 = value(axn)[1]
#     # @test tag(all1) == "all"
#     # @test value(all1) isa XmlDictType
#     # use1 = value(all1)["usersort"]
#     # @test use1 isa XmlDictType
#     # @test use1[:declaration] == "N1"
#     # @test PNML._attribute(use1, :declaration) == "N1"

#     # all2 = value(axn)[2]
#     # @test tag(all2) == "all"
#     # @test value(all2) isa XmlDictType
#     # use2 = value(all2)["usersort"]
#     # @test use2 isa XmlDictType
#     # @test use2[:declaration] == "N2"
#     # @test PNML._attribute(use2, :declaration) == "N2"
# end
