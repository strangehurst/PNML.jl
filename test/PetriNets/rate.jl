using PNML, EzXML, ..TestUtils, JET
using PNML: Maybe, tag, pid, xmlnode
using .PnmlIDRegistrys: PnmlIDRegistry as IDRegistry

@testset "get rate label" begin
    n = parse_node(xml"""<transition id ="birth">
        <rate> <text>0.3</text> </rate>
    </transition>""", reg=IDRegistry())
    l = PNML.labels(n)
    @test PNML.tag(first(l)) === :rate # only label
    @test PNML.get_label(n, :rate) === first(PNML.labels(n))
    @test PNML.rate(n) ≈ 0.3

    @test_call PNML.has_labels(n)
    @test_call PNML.labels(n)
    @test_call PNML.has_label(n, :rate)
    @test_call PNML.get_label(n, :rate)
    @test_call PNML.rate(n)
end
