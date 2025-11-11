using PNML, ..TestUtils, JET

println("RATE")
@testset "get rate label $pntd" for pntd in PnmlTypes.all_nettypes()
    parse_context = PNML.parser_context()

    trans = PNML.Parser.parse_transition(xml"""<transition id ="birth"><rate> <text>0.3</text> </rate></transition>""",
            pntd; parse_context)
    #@show lab = PNML.labels(trans)

    @test PNML.has_labels(trans) === true
    @test PNML.has_label(trans, :rate) === true
    @test PNML.get_label(trans, :rate) === PNML.labels(trans)[:rate]
    @test PNML.get_label(trans, :rate) !== nothing
    #@show trans
    @test PNML.rate_value(trans) ≈ 0.3

    @test_call PNML.has_labels(trans)
    @test_call PNML.has_label(trans, :rate)
    @test_call PNML.get_label(trans, :rate)
    @test_call PNML.labels(trans)
    @test_call PNML.rate_value(trans)

    tr = @inferred PNML.rate_value(trans)
    @test eltype(tr) == PNML.value_type(Labels.Rate)
end

# Ensure not seeing very similar label while getting default.
@testset "get defaulted rate label $pntd" for pntd in PnmlTypes.all_nettypes()
    parse_context = PNML.parser_context()
    node = xml"""<transition id ="birth">
                    <rateX> <text> 0.3 </text> </rateX>
                 </transition>"""
    tr = @test_logs(match_mode=:any,
                    (:info, r"add PnmlLabel"),
                    PNML.Parser.parse_transition(node, pntd; parse_context))
    @test PNML.rate_value(tr) ≈ 0.0
end


# @testset "delay label $pntd" for pntd in PnmlTypes.all_nettypes()
#     parse_context = PNML.parser_context()
#     # From [Tina .pnml formt](file://~/PetriNet/tina-3.7.5/doc/html/formats.html#5)
#     # This bit may be from the pre-standard era.
#     # <ci> is a variable(constant) like pi, infinity.
#     # <cn> is a number (real)
#     # interval [4,9]
#     node = xml"""<transition id ="t6">
#         <delay>
#             <interval xmlns="http://www.w3.org/1998/Math/MathML" closure="closed">
#                 <cn>4.0</cn>
#                 <cn>9.0</cn>
#             </interval>
#         </delay>
#     </transition>"""
#     #! This has Float64 and Int
#     println()
#     @show t = parse_transition(node, pntd; parse_context)::Transition
#     println()
#     @test has_label(labels(t), "delay")
#     @show has_label(labels(t), "delay")
#     #@show dump(t)

#     ls = labels(t)
#     #elements(label)

#     @show typeof(ls) length(ls)
#     #@show typeof(first(ls))
#     println()
#     @show PNML.get_label(ls, "delay") #! debug
#     @show PNML.labelof(t, "delay") #! debug
#     @test PNML.get_label(ls, "delay") == PNML.labelof(t, "delay")
#     @test PNML.delay_value(t) isa Tuple
#     #println()

#     # unbounded interval [4,∞)
#     node = xml"""<transition id ="t7">
#         <delay>
#             <interval xmlns="http://www.w3.org/1998/Math/MathML" closure="closed-open">
#                 <cn>4</cn>
#                 <ci>infty</ci>
#             </interval>
#         </delay>
#     </transition>"""
#     t = parse_transition(node, pntd; parse_context)::Transition
#     @test PNML.delay_value(t) isa Tuple
#     #@show PNML.labelof(t, "delay") #! debug
#     #println()

#     # interval (3,5)
#     node = xml"""<transition id ="t8">
#         <delay>
#             <interval xmlns="http://www.w3.org/1998/Math/MathML" closure="open">
#                 <cn>3</cn>
#                 <cn>5</cn>
#             </interval>
#         </delay>
#     </transition>"""
#     t = parse_transition(node, pntd; parse_context)::Transition
#     @test PNML.delay_value(t) isa Tuple
#     #@show PNML.labelof(t, "delay") #! debug
#     #println()

# end
