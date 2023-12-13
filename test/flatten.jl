using PNML, EzXML, ..TestUtils, JET
using PNML: tag, pid

const str = """
<?xml version="1.0"?>
    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
        <net id="net0" type="pnmlcore">
            <page id="page1">
                <place id="p1"/>
                <transition id ="t1"/>
                <arc id="a1" source="p1" target="t1"/>
                <arc id="a12" source="t1" target="rp1"/>
                <referencePlace id="rp1" ref="p2"/>
            </page>
            <page id="page2">
                <place id="p2"/>
                <transition id ="t2"/>
                <arc id="a2" source="t2" target="p2"/>
                <arc id="a22" source="t2" target="rp2"/>
                <referencePlace id="rp2" ref="p3"/>
                <referenceTransition id="rt2" ref="t3"/>
            </page>
            <page id="page3">
                <place id="p3"/>
                <transition id ="t3"/>
                <arc id="a3" source="t3" target="p3"/>
            </page>
        </net>
    </pnml>
"""

@testset "deref1" begin
    model = parse_str(str)
    net = PNML.first_net(model)
    @test_call PNML.first_net(model)
    @test length(PNML.allpages(net)) == 3
    PNML.flatten_pages!(net)
    @test length(PNML.allpages(net)) == 1
    @test typeof(net) <: PNML.PnmlNet
end

@testset "deref2" begin
    model = parse_str(str)
    PNML.flatten_pages!(model)
    net = PNML.first_net(model)
    @test length(PNML.allpages(net)) == 1
    @test typeof(net) <: PNML.PnmlNet
end
