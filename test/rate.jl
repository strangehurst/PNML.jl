using PNML, JET

include("TestUtils.jl")
using .TestUtils

println("RATE")
@testset "get rate label $pntd" for pntd in PnmlTypes.all_nettypes()
    net = PnmlNet(pntd, :fake)
    PNML.fill_nonhl!(net)
    PNML.fill_labelp!(net)

    trans = PNML.Parser.parse_transition(xml"""<transition id ="birth">
                                                 <rate> <text>0.3</text> </rate>
                                               </transition>""",
            pntd, net)
    #@show lab = PNML.labels(trans)

    @test get_label(trans, :rate) === labels(trans)[:rate]
    @test get_label(trans, :rate) !== nothing
    @test PNML.rate_value(trans) ≈ 0.3
    r = PNML.get_label(trans, :rate)
    @test occursin(r"^Rate", sprint(show, r))
    @test eltype(r) == Float64
    @test sortref(r) isa AbstractSortRef
    @test refid(sortref(r)) === :real
    @test sortof(r) isa RealSort

    @test_call PNML.get_label(trans, :rate)
    @test_call PNML.labels(trans)
    @test_call PNML.rate_value(trans)

    tr = @inferred PNML.rate_value(trans)
    @test eltype(tr) == PNML.value_type(Labels.Rate)
end
