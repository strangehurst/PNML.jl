
include("TestUtils.jl")
using .TestUtils
using EzXML: EzXML
using XMLDict: XMLDict

@testset "name $pntd" for pntd in PnmlTypes.core_nettypes()
    net = PnmlNet(pntd, :fake)
    PNML.fill_builtin_sorts!(net)
    PNML.fill_builtin_labelparsers!(net)

    n = @test_logs((:warn, r"^<name> missing <text>"),
            PNML.Parser.parse_name(xml"<name></name>", pntd;
                                    net, parentid=:xxx))::PNML.AbstractLabel
    @test PNML.text(n) == ""

    n = @test_logs((:warn, r"^<name> missing <text>"),
            PNML.Parser.parse_name(xml"<name>stuff</name>", pntd;
                                    net, parentid=:xxx))
    @test PNML.text(n) == "stuff"

    @test n.graphics === nothing
    @test n.toolspecinfos === nothing || isempty(n.toolspecinfos)

    n = PNML.Parser.parse_name(xml"<name><text>some name</text></name>", pntd; net, parentid=:xxx)
    @test n isa PNML.Name
    @test PNML.text(n) == "some name"

    n = PNML.Parser.parse_name(xml"""
        <name>
            <text>some name2</text>
            <graphics/>
        </name>""",
        pntd; net, parentid=:xxx)
    @test PNML.text(n) == "some name2"
    @test has_graphics(n) == true

    #TODO add toolinfo
    n = PNML.Parser.parse_name(xml"""
        <name>
            <text>some name3</text>
            <toolspecific tool="faketool" version="1.2.3" />
        </name>""",
        pntd; net, parentid=:xxx)
    @test PNML.text(n) == "some name3"

    #TODO add toolinfo
    n = @test_logs((:warn, ":xxx ignoring unexpected child of <name>: 'unknown'"),
            PNML.Parser.parse_name(xml"""
                <name>
                    <text>some name4</text>
                    <unknown/>
                </name>""",
                pntd; net, parentid=:xxx))

    old_cfg = PNML.CONFIG[].text_element_optional
    PNML.CONFIG[].text_element_optional = false
    n = @test_throws(ArgumentError,
            PNML.Parser.parse_name(xml"<name>stuff</name>", pntd;
                                    net, parentid=:xxx))
    PNML.CONFIG[].text_element_optional =  old_cfg
end
