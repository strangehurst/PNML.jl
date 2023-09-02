using PNML, EzXML, ..TestUtils, JET
using PNML: Maybe, tag, pid, xmlnode

println()

@testset "get rate label $pntd" for pntd in all_nettypes()
    tr = PNML.parse_transition(xml"""<transition id ="birth">
        <rate> <text>0.3</text> </rate>
    </transition>""", pntd, registry())
    lab = PNML.labels(tr)
    Base.redirect_stdio(stdout=testshow, stderr=testshow) do;
        @show tr lab PNML.rate(tr)
    end
    @test PNML.tag(first(lab)) === :rate # assumes is only label
    @test PNML.has_labels(tr) isa Bool
    @test PNML.has_label(tr, :rate) isa Bool
    @test PNML.get_label(tr, :rate) === first(PNML.labels(tr))
    @test PNML.get_label(tr, :rate) !== nothing
    @test PNML.rate(tr) ≈ 0.3

    @test_call PNML.has_labels(tr)
    @test_call PNML.has_label(tr, :rate)
    @test_call PNML.get_label(tr, :rate)
    @test_call PNML.labels(tr)
    #println("\ntr"); dump(tr)
    @test_call PNML.rate(tr)
end

# Ensure not seeing very similar label while getting default.
@testset "get defaulted rate label $pntd" for pntd in all_nettypes()
    tr = PNML.parse_transition(xml"""<transition id ="birth">
        <rateX> <text>0.3</text> </rateX>
    </transition>""", pntd, registry())
    #println("defaulted rate"); dump(PNML.labels(tr))
    @test PNML.rate(tr) ≈ 0.0
end
