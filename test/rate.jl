using PNML, ..TestUtils, JET

println("RATE")
@testset "get rate label $pntd" for pntd in PnmlTypes.all_nettypes()
    parse_context = PNML.parser_context()

    trans = PNML.Parser.parse_transition(xml"""<transition id ="birth"><rate> <text>0.3</text> </rate></transition>""",
            pntd; parse_context)
    lab = PNML.labels(trans)
    @test PNML.tag(first(lab)) === "rate" # assumes is only label
    @test PNML.has_labels(trans) === true
    @test PNML.has_label(trans, "rate") === true
    @test PNML.get_label(trans, "rate") === first(PNML.labels(trans))
    @test PNML.get_label(trans, "rate") !== nothing
    #@show trans
    @test PNML.rate_value(trans, pntd) ≈ 0.3

    @test_call PNML.has_labels(trans)
    @test_call PNML.has_label(trans, "rate")
    @test_call PNML.get_label(trans, "rate")
    @test_call PNML.labels(trans)
    @test_call PNML.rate_value(trans, pntd)

    tr = @inferred PNML.rate_value(trans, pntd)
        @test eltype(tr) == PNML.value_type(Labels.Rate, PNML.nettype(trans))
end

# Ensure not seeing very similar label while getting default.
@testset "get defaulted rate label $pntd" for pntd in PnmlTypes.all_nettypes()
    parse_context = PNML.parser_context()
    node = xml"""<transition id ="birth">
                    <rateX> <text> 0.3 </text> </rateX>
                 </transition>"""
    tr = @test_logs((:warn, "found unexpected label of <transition> id=birth: rateX"),
                    PNML.Parser.parse_transition(node, pntd; parse_context))
    @test PNML.rate_value(tr, pntd) ≈ 0.0
end
