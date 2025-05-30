using PNML, ..TestUtils, JET

println("RATE")
@testset "get rate label $pntd" for pntd in PnmlTypeDefs.all_nettypes()
    @with PNML.idregistry => PnmlIDRegistry() begin
        ddict = PNML.decldict(PNML.idregistry[])
        trans = PNML.Parser.parse_transition(xml"""<transition id ="birth"><rate> <text>0.3</text> </rate></transition>""", pntd; ddict)
        lab = PNML.labels(trans)
        @test PNML.tag(first(lab)) === "rate" # assumes is only label
        @test PNML.has_labels(trans) === true
        @test PNML.has_label(trans, "rate") === true
        @test PNML.get_label(trans, "rate") === first(PNML.labels(trans))
        @test PNML.get_label(trans, "rate") !== nothing
        #@show trans
        @test PNML.rate_value(trans) ≈ 0.3

        @test_call PNML.has_labels(trans)
        @test_call PNML.has_label(trans, "rate")
        @test_call PNML.get_label(trans, "rate")
        @test_call PNML.labels(trans)
        @test_call PNML.rate_value(trans)

        tr = @inferred PNML.rate_value(trans)
        @test eltype(tr) == PNML.rate_value_type(PNML.nettype(trans))
    end
end

# Ensure not seeing very similar label while getting default.
@testset "get defaulted rate label $pntd" for pntd in PnmlTypeDefs.all_nettypes()
    tr = @with PNML.idregistry => PnmlIDRegistry() begin
            ddict = PNML.decldict(PNML.idregistry[])
            PNML.Parser.parse_transition(xml"""
                <transition id ="birth">
                  <rateX> <text>0.3</text> </rateX>
                </transition>""", pntd; ddict)
    end
    @test PNML.rate_value(tr) ≈ 0.0
end
