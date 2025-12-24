using PNML, ..TestUtils, JET, NamedTupleTools
using EzXML: EzXML
using XMLDict: XMLDict

# timed petri net is a metamodel

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
    #@show t
    @test has_labels(t) == true
    @test has_label(labels(t), :delay) == true

    @test PNML.get_label(labels(t), :delay) == PNML.labelof(t, :delay)
    @show PNML.labelof(t, :delay)
    #! @test PNML.delay_value(t)::Tuple == ("closed", 4.0, 9.0)

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
    #! @test PNML.delay_value(t)::Tuple == ("closed-open", 4, Base.Inf)

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
    #! @test PNML.delay_value(t)::Tuple == ("open", 3.0, 5.0) #! why float

    del = PNML.labelof(t, :delay)
    #@show elements(del)["interval"]
    @test elements(del)["interval"][:closure] == "open"
    @test elements(del)["interval"]["cn"] == ["3", "5"]

end
