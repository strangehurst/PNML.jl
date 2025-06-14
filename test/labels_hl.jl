using PNML, ..TestUtils, JET, NamedTupleTools, AbstractTrees
using EzXML: EzXML
using XMLDict: XMLDict


@testset "type $pntd" for pntd in PnmlTypeDefs.all_nettypes(ishighlevel)
    # Add usersort, namedsort duo as test context.
    ctx = PNML.parser_context()
    PNML.namedsorts(ctx.ddict)[:N2] = PNML.NamedSort(:N2, "N2", DotSort(ctx.ddict), ctx.ddict)
    PNML.usersorts(ctx.ddict)[:N2]  = PNML.UserSort(:N2, ctx.ddict)

    n1 = xml"""
<type>
    <text>N2</text>
    <structure> <usersort declaration="N2"/> </structure>
</type>
    """
    typ = PNML.Parser.parse_sorttype(n1, pntd; parse_context=ctx)::SortType
    @test text(typ) == "N2"
    @test PNML.sortref(typ) isa PNML.UserSort # wrapping DotSort
    @test PNML.sortof(typ) == DotSort(ctx.ddict) #! does the name of a sort affect equal Sorts?
    @test PNML.has_graphics(typ) == false
    @test PNML.has_labels(typ) == false
    @test !occursin("Graphics", sprint(show, typ))
end

@testset "HL initMarking" begin

     @testset "3`dot $pntd" for pntd in PnmlTypeDefs.all_nettypes(ishighlevel)
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
        ctx = PNML.parser_context()

        # Marking is a multiset in high-level nets with sort matching placetype, :dot.
        placetype = SortType("XXX", PNML.usersort(ctx.ddict, :dot), ctx.ddict)

        mark = parse_hlinitialMarking(node, placetype, pntd; parse_context=ctx)
        #@show mark
        @test mark isa PNML.marking_type(pntd)

        @test PNML.term(mark) isa PNML.Bag
        @test text(mark) == "3`dot"
        #println(); flush(stdout)
        #@show UserSort(:dot) DotConstant
        #@show PNML.pnmlmultiset(UserSort(:dot, ddict), DotConstant(ddict); ddict)
        #PnmlMultiset{(:dot,), DotConstant}(DotConstant(ddict))

        @test PNML.has_graphics(mark) == false # This instance does not have any graphics.
        @test PNML.has_labels(mark) == false # Labels do not themselves have `Labels`, but you may ask.
        #@show PNML.toexpr(term(mark), NamedTuple(), ddict)
        @test eval(PNML.toexpr(term(mark), NamedTuple(), ctx.ddict)) isa PNML.PnmlMultiset
        # @test arity(markterm) == 2
        # @test inputs(markterm)[1] == NumberConstant(3, PositiveSort())
        # @test inputs(markterm)[2] == DotConstant(ddict)

        #TODO HL implementation not complete:
        #TODO  evaluate the HL expression, check place sorttype
    end

    # 0-arity operators are constants
    # @testset "useroperator" for pntd in PnmlTypeDefs.all_nettypes(ishighlevel)
    #     println("\nuseroperator $pntd")
    #     node = xml"""
    #     <hlinitialMarking>
    #         <text>useroperator</text>
    #         <structure>
    #             <useroperator declaration="uop"/>
    #         </structure>
    #     </hlinitialMarking>
    #     """
    #     @with PNML.idregistry => PnmlIDRegistry() begin
    #         PNML.namedoperators()[:uop] = PNML.NamedOperator(:uop, "uop")
    #         PNML.usersorts(ddict)[:uop] = UserSort(:dot)
    #         placetype = SortType("YYY", PNML.usersort(ddict, :uop))
    #         mark = parse_hlinitialMarking(node, placetype, pntd)
    #         @test mark isa HLMarking
    #     end
    # end

    # add two multisets: another way to express 3 + 2
    @testset "3`dot ++ 2'dot" for pntd in PnmlTypeDefs.all_nettypes(ishighlevel)
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
        ctx = PNML.parser_context()
        placetype = SortType("dot sorttype", PNML.usersort(ctx.ddict, :dot), ctx.ddict)
        mark = PNML.Parser.parse_hlinitialMarking(node, placetype, pntd; parse_context=ctx)
        #TODO add tests
    end
    # The constant eight.
    @testset "1`8" for pntd in PnmlTypeDefs.all_nettypes(ishighlevel)
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
        ctx = PNML.parser_context()
        placetype = SortType("positive sorttype", PNML.usersort(ctx.ddict, :positive), ctx.ddict)
        mark = parse_hlinitialMarking(node, placetype, pntd; parse_context=ctx)
        val = eval(toexpr(term(mark), NamedTuple(), ctx.ddict))::PNML.PnmlMultiset{<:Any,<:Any}
        # @show PNML.basis(val) # isa UserSort
        #@show val NumberConstant(8, PNML.usersort(ctx.ddict, :positive), ctx.ddict)()
        #@show PNML.usersort(ctx.ddict, :positive)
        @test PNML.multiplicity(val, NumberConstant(8, PNML.usersort(ctx.ddict, :positive), ctx.ddict)()) == 1
        @test PNML.sortof(PNML.basis(val)::UserSort) === PNML.PositiveSort()
        @test NumberConstant(8, PNML.usersort(ctx.ddict, :positive), ctx.ddict)() in multiset(val)
     end

    # This is the same as when the element is omitted.
    @testset "x" for pntd in PnmlTypeDefs.all_nettypes(ishighlevel)
        node = xml"""
        <hlinitialMarking>
        </hlinitialMarking>
        """
        ctx = PNML.parser_context()
        placetype = SortType("testdot", PNML.usersort(ctx.ddict, :dot), ctx.ddict)
        mark = parse_hlinitialMarking(node, placetype, pntd; parse_context=ctx)
    end

    #println()
end





# @testset "<All,All>" for pntd in PnmlTypeDefs.all_nettypes(ishighlevel)
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

#     @show placetype = SortType("XXX", ProductSort(UserSort[UserSort(:dot),UserSort(:dot)]))

#     mark = PNML.parse_hlinitialMarking(node, placetype, pntd)

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

# @testset "hlinscription $pntd" for pntd in PnmlTypeDefs.all_nettypes(ishighlevel)
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
#     dd.variabledecls[:x] = PNML.VariableDeclaration(:x, "", DotSort())
#     dd.variabledecls[:v] = PNML.VariableDeclaration(:v, "", DotSort())
#     @show placetype = SortType("XXX", UserSort(:dot))


#     insc = @test_logs(match_mode=:all,
#             (:warn,"ignoring unexpected child of <hlinscription>: 'unknown'"),
#             PNML.Parser.parse_hlinscription(n1, pntd)

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

# @testset "structure $pntd" for pntd in PnmlTypeDefs.all_nettypes(ishighlevel)
#     node = xml"""
#      <structure>
#         <tuple>
#             <subterm><all><usersort declaration="N1"/></all></subterm>
#             <subterm><all><usersort declaration="N2"/></all></subterm>
#         </tuple>
#      </structure>
#     """
#     # expected structure: tuple -> subterm -> all -> usersort -> declaration

#     stru = PNML.parse_structure(node, pntd)
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



# # Conditions are for everybody, but we cannot (feasibily) test high-level
# @testset "condition $pntd" for pntd in PnmlTypeDefs.all_nettypes(ishighlevel)
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
#         # dd.namedoperators[:cts] = PNML.NamedOperator(:cts, "")
#         # dd.namedoperators[:ack] = PNML.NamedOperator(:ack, "")

#         cond = @test_logs(match_mode=:all,
#                 (:warn, "ignoring unexpected child of <condition>: 'unknown'"),
#                 PNML.parse_condition(node, pntd)
#         @test cond isa PNML.condition_type(pntd)
#         @show cond
#         @test text(cond) == "pt==cts||pt==ack"
#         # @test value(cond) isa PNML.Operator
#         # @test tag(value(cond)) == :or
#         @test PNML.has_graphics(cond) == true
#         @test PNML.has_labels(cond) == false
#     end
# end
