using PNML, ..TestUtils, JET, XMLDict

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
