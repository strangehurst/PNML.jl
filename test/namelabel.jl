using PNML, ..TestUtils, JET, NamedTupleTools, OrderedCollections
using EzXML: EzXML
using XMLDict: XMLDict

@testset "name $pntd" for pntd in PnmlTypes.core_nettypes()
    parse_context = PNML.parser_context()
    n = @test_logs((:warn, r"^<name> missing <text>"),
            PNML.Parser.parse_name(xml"<name></name>", pntd;
                                    parse_context, parentid=:xxx))::PNML.AbstractLabel
    @test PNML.text(n) == ""

    n = @test_logs((:warn, r"^<name> missing <text>"),
            PNML.Parser.parse_name(xml"<name>stuff</name>", pntd;
                                    parse_context, parentid=:xxx))
    @test PNML.text(n) == "stuff"

    @test n.graphics === nothing
    @test n.toolspecinfos === nothing || isempty(n.toolspecinfos)

    n = PNML.Parser.parse_name(xml"<name><text>some name</text></name>", pntd; parse_context, parentid=:xxx)
    @test n isa PNML.Name
    @test PNML.text(n) == "some name"
    #TODO add parse_graphics
    #TODO add toolinfo

end
