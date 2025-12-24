using PNML, ..TestUtils, JET, NamedTupleTools
using EzXML: EzXML
using XMLDict: XMLDict
# todo parse_arctype

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
