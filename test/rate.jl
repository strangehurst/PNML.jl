using PNML, ..TestUtils, JET

println("RATE")
@testset "get rate label $pntd" for pntd in PnmlTypes.all_nettypes()
    parse_context = PNML.parser_context()

    trans = PNML.Parser.parse_transition(xml"""<transition id ="birth"><rate> <text>0.3</text> </rate></transition>""",
            pntd; parse_context)
    #@show lab = PNML.labels(trans)

    @test has_labels(trans) === true
    @test has_label(trans, :rate) === true
    @test get_label(trans, :rate) === labels(trans)[:rate]
    @test get_label(trans, :rate) !== nothing
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

println("PRIORITY")
@testset "get priority label $pntd" for pntd in PnmlTypes.all_nettypes()
    parse_context = PNML.parser_context()

    trans = PNML.Parser.parse_transition(
        xml"""<transition id ="birth"><priority> <text>0.3</text> </priority></transition>""",
            pntd; parse_context)
    #@show lab = PNML.labels(trans)

    @test PNML.has_labels(trans) === true
    @test PNML.has_label(trans, :priority) === true
    @test PNML.get_label(trans, :priority) === PNML.labels(trans)[:priority]
    @test PNML.get_label(trans, :priority) !== nothing
    #@show trans
    @test PNML.priority_value(trans) ≈ 0.3

    @test_call PNML.has_labels(trans)
    @test_call PNML.has_label(trans, :priority)
    @test_call PNML.get_label(trans, :priority)
    @test_call PNML.labels(trans)
    @test_call PNML.priority_value(trans)

    tr = @inferred PNML.priority_value(trans)
    @test eltype(tr) == PNML.value_type(Labels.Priority)
end

# Ensure not seeing very similar label while getting default.
@testset "get defaulted priority label $pntd" for pntd in PnmlTypes.all_nettypes()
    parse_context = PNML.parser_context()
    node = xml"""<transition id ="birth">
                    <priorityX> <text> 0.3 </text> </priorityX>
                 </transition>"""
    tr = @test_logs(match_mode=:any,
                    (:info, r"add PnmlLabel"),
                    PNML.Parser.parse_transition(node, pntd; parse_context))
    @test PNML.priority_value(tr) ≈ 1.0
end

println("DELAY")
@testset "delay label $pntd" for pntd in PnmlTypes.all_nettypes()
    #println("delay label $pntd")
    parse_context = PNML.parser_context()
    # From [Tina .pnml formt](file://~/PetriNet/tina-3.7.5/doc/html/formats.html#5)
    # This bit may be from the pre-standard era.
    # <ci> is a variable(constant) like pi, infinity.
    # <cn> is a number (real)
    # interval [4,9]
    node = xml"""<transition id ="t6">
        <delay>
            <interval xmlns="http://www.w3.org/1998/Math/MathML" closure="closed">
                <cn>4.0</cn>
                <cn>9.0</cn>
            </interval>
        </delay>
    </transition>"""
    #! This has Float64 and Int
    t = @test_logs((:info, "add PnmlLabel :delay to :t6"),
        parse_transition(node, pntd; parse_context)::Transition)
    @test has_labels(t) == true
    @test has_label(labels(t), :delay) == true

    @test PNML.get_label(labels(t), :delay) == PNML.labelof(t, :delay)
    @test PNML.delay_value(t)::Tuple == ("closed", 4.0, 9.0)

    del = PNML.labelof(t, :delay)
    #@show elements(del)["interval"]
    #! XXX where did xmlns dissappear
    #@test elements(del)["interval"][:xmlns] == "http://www.w3.org/1998/Math/MathML"
    @test elements(del)["interval"][:closure] == "closed"
    @test elements(del)["interval"]["cn"] == ["4.0", "9.0"]

    # unbounded interval [4,∞)
    node = xml"""<transition id ="t7">
        <delay>
            <interval xmlns="http://www.w3.org/1998/Math/MathML" closure="closed-open">
                <cn>4</cn>
                <ci>infty</ci>
            </interval>
        </delay>
    </transition>"""
    t = @test_logs((:info, "add PnmlLabel :delay to :t7"),
        parse_transition(node, pntd; parse_context)::Transition)
    @test PNML.get_label(labels(t), :delay) == PNML.labelof(t, :delay)
    @test PNML.delay_value(t)::Tuple == ("closed-open", 4, Base.Inf)

    del = PNML.labelof(t, :delay)
    #@show elements(del)["interval"]
    @test elements(del)["interval"][:closure] == "closed-open"
    @test elements(del)["interval"]["cn"] == "4"
    @test elements(del)["interval"]["ci"] == "infty"


    # interval (3,5)
    node = xml"""<transition id ="t8">
        <delay>
            <interval xmlns="http://www.w3.org/1998/Math/MathML" closure="open">
                <cn>3</cn>
                <cn>5</cn>
            </interval>
        </delay>
    </transition>"""
    t = @test_logs((:info, "add PnmlLabel :delay to :t8"),
        parse_transition(node, pntd; parse_context)::Transition)
    @test PNML.get_label(labels(t), :delay) == PNML.labelof(t, :delay)
    #@show PNML.delay_value(t)::Tuple
    @test PNML.delay_value(t)::Tuple == ("open", 3.0, 5.0) #! why float

    del = PNML.labelof(t, :delay)
    #@show elements(del)["interval"]
    @test elements(del)["interval"][:closure] == "open"
    @test elements(del)["interval"]["cn"] == ["3", "5"]

end
