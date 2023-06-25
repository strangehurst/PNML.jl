using PNML, EzXML, ..TestUtils, JET
using PNML: Maybe, tag, pid, xmlnode

println()

@testset "get rate label" begin
    tr = PNML.parse_transition(xml"""<transition id ="birth">
        <rate> <text>0.3</text> </rate>
    </transition>""", PnmlCoreNet(), registry())
    lab = PNML.labels(tr)
    #@show tr lab
    #@show PNML.rate(tr)
    @test PNML.tag(first(lab)) === :rate # only label
    @test PNML.get_label(tr, :rate) === first(PNML.labels(tr))
    @test PNML.rate(tr) ≈ 0.3

    @test_call PNML.has_labels(tr)
    @test_call PNML.labels(tr)
    @test_call PNML.has_label(tr, :rate)
    @test_call PNML.get_label(tr, :rate)
    @test_call broken=true PNML.rate(tr)
end
