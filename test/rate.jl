using PNML, ..TestUtils, JET

println("RATE")
@testset "get rate label $pntd" for pntd in all_nettypes()
    @with PNML.idregistry => registry() PNML.DECLDICT => PNML.DeclDict() begin
        PNML.fill_nonhl!(PNML.DECLDICT[])
        trans = PNML.parse_transition(xml"""<transition id ="birth"><rate> <text>0.3</text> </rate></transition>""", pntd)
        lab = PNML.labels(trans)
        @test PNML.tag(first(lab)) === :rate # assumes is only label
        @test PNML.has_labels(trans) === true
        @test PNML.has_label(trans, :rate) === true
        @test PNML.get_label(trans, :rate) === first(PNML.labels(trans))
        @test PNML.get_label(trans, :rate) !== nothing
        @test PNML.rate(trans) ≈ 0.3

        @test_call PNML.has_labels(trans)
        @test_call PNML.has_label(trans, :rate)
        @test_call PNML.get_label(trans, :rate)
        @test_call PNML.labels(trans)
        @test_call PNML.rate(trans)

        tr = @inferred Maybe{PNML.TransitionRate} PNML.rate(trans)
        @test eltype(tr) == PNML.rate_value_type(PNML.nettype(trans))
    end
end

# Ensure not seeing very similar label while getting default.
@testset "get defaulted rate label $pntd" for pntd in all_nettypes()
    tr = @test_logs((:warn, "unexpected label of <transition> id=birth: rateX"),
        @with(PNML.idregistry => registry(), PNML.DECLDICT => PNML.DeclDict(),
            PNML.parse_transition(xml"""
            <transition id ="birth">
              <rateX> <text>0.3</text> </rateX>
            </transition>""", pntd)))
    @test PNML.rate(tr) ≈ 0.0
end
