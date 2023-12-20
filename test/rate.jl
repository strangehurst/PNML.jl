using PNML, EzXML, ..TestUtils, JET
using PNML: Maybe, tag, pid

@testset "get rate label $pntd" for pntd in all_nettypes()
    tr = PNML.parse_transition(xml"""<transition id ="birth">
        <rate> <text>0.3</text> </rate>
    </transition>""", pntd, registry())
    lab = PNML.labels(tr)
    @test PNML.tag(first(lab)) === :rate # assumes is only label
    @test PNML.has_labels(tr) === true
    @test PNML.has_label(tr, :rate) === true
    @test PNML.get_label(tr, :rate) === first(PNML.labels(tr))
    @test PNML.get_label(tr, :rate) !== nothing
    @test PNML.rate(tr) ≈ 0.3

    @test_call PNML.has_labels(tr)
    @test_call PNML.has_label(tr, :rate)
    @test_call PNML.get_label(tr, :rate)
    @test_call PNML.labels(tr)
    @test_call PNML.rate(tr)
end

# Ensure not seeing very similar label while getting default.
@testset "get defaulted rate label $pntd" for pntd in all_nettypes()
    tr = @test_logs (:warn, "unexpected label of <transition> id=birth: rateX") PNML.parse_transition(
            xml"""<transition id ="birth"><rateX> <text>0.3</text> </rateX></transition>""",
            pntd, registry())
    @test PNML.rate(tr) ≈ 0.0
end
