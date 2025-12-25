using PNML, ..TestUtils, JET, NamedTupleTools
using EzXML: EzXML
using XMLDict: XMLDict

println("PRIORITY")
@testset "get priority label $pntd" for pntd in PnmlTypes.all_nettypes()
    parse_context = PNML.parser_context()

    trans = PNML.Parser.parse_transition(
        xml"""<transition id ="birth">
                <priority> <text>0.3</text> </priority>
            </transition>""",
            pntd; parse_context)
    #@show lab = PNML.labels(trans)

    @test PNML.has_labels(trans) === true
    @test PNML.labelof(trans, :nosuchlabel) == nothing
    lab = PNML.labelof(trans, :priority)
    @test PNML.has_label(trans, :priority) === true
    @test PNML.get_label(trans, :priority) === PNML.labels(trans)[:priority]
    @test PNML.get_label(trans, :priority) == lab != nothing
    @test PNML.priority_value(trans) ≈ 0.3

    @test_call PNML.has_labels(trans)
    @test_call PNML.has_label(trans, :priority)
    @test_call PNML.get_label(trans, :priority)
    @test_call PNML.labels(trans)
    @test_call PNML.priority_value(trans)

    tr = @inferred PNML.priority_value(trans)
    @test eltype(tr) == PNML.value_type(Labels.Priority)
end

@testset "get defaulted priority label $pntd" for pntd in PnmlTypes.all_nettypes()
    parse_context = PNML.parser_context()
    node = xml"""<transition id ="birth">
                    <priorityX> <text> 0.3 </text> </priorityX>
                 </transition>"""
    tr = @test_logs(match_mode=:any, (:info, r"add PnmlLabel"),
                    PNML.Parser.parse_transition(node, pntd; parse_context))
    @test PNML.priority_value(tr) ≈ 1.0
end
