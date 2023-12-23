using PNML, EzXML, ..TestUtils, JET
using PNML: tag, pid, parse_graphics, parse_tokengraphics, x, y

@testset "coordinate" begin
    PNML.Coordinate(1, 2)
    PNML.Coordinate(1.1, 2.2)
    @test_opt PNML.Coordinate(1, 2)
    @test_call PNML.Coordinate(1, 2)
    @test_opt PNML.Coordinate(1.1, 2.2)
    @test_call PNML.Coordinate(1.1, 2.2)
    #TODO more tests
end

@testset "graphics $pntd" for pntd in all_nettypes()
    str = """
    <graphics>
     <offset x="1.0" y="2.0" />
     <line  color="linecolor" shape="line" style="solid" width="1.0"/>
     <position  x="1.0" y="2" />
     <position  x="3.0" y="4" />
     <dimension x="5.0" y="6" />
     <offset    x="7.0" y="8" /><!-- override first offset -->
     <fill  color="fillcolor" gradient-color="none" gradient-rotation="horizontal"/>
     <font align="center" family="Dialog" rotation="0.0"  size="11.5"
           style="normal" weight="normal" />
    <unexpected/>
    </graphics>
    """
    n = @test_logs (:warn,"graphics ignoring <graphics> child '<unexpected/>'") parse_graphics(xmlroot(str), pntd, registry())

    # There can only be one offset, last tag parsed wins.
    @test x(n.offset) == 7.0 && y(n.offset) == 8.0
    @test n.offset == PNML.Coordinate(7.0, 8.0)
    @test n.offset == PNML.Coordinate(7, 8.0)
    @test n.offset == PNML.Coordinate(7, 8)
    @test n.dimension == PNML.Coordinate(5.0, 6.0)
    @test n.offset isa PNML.Coordinate
    @test n.dimension isa PNML.Coordinate
    @test n.positions isa Vector{PNML.Coordinate{PNML.coordinate_value_type()}}
    @test length(n.positions) == 2
    @test n.positions == [PNML.Coordinate(1.0, 2.0), PNML.Coordinate(3.0, 4.0)]

    @test n.line isa PNML.Line
    @test n.line.color == "linecolor"
    @test n.line.shape == "line"
    @test n.line.style == "solid"
    @test n.line.width == "1.0"

    @test n.fill isa PNML.Fill
    @test n.fill.color == "fillcolor"
    @test isempty(n.fill.image) # === nothing
    @test n.fill.gradient_color == "none"
    @test n.fill.gradient_rotation == "horizontal"

    @test n.font isa PNML.Font
    @test n.font.family == "Dialog"
    @test n.font.style == "normal"
    @test n.font.weight == "normal"
    @test n.font.size == "11.5"
    @test isempty(n.font.decoration) # === nothing
    @test n.font.align == "center"
    @test n.font.rotation == "0.0"
end

@testset "graphics exception $pntd" for pntd in all_nettypes()
    str0 = """<bogus x="1" y="2" />"""
    @test_throws r"^ArgumentError" PNML.parse_graphics_coordinate(xmlroot(str0), pntd, registry())
end

@testset "tokengraphics $pntd" for pntd in all_nettypes()
    str0 = """<tokengraphics></tokengraphics>"""
    n = @test_logs (:warn,"tokengraphics does not have any <tokenposition> elements") parse_tokengraphics(xmlroot(str0), pntd, registry())
    @test n isa PNML.TokenGraphics
    @test length(n.positions) == 0

    str1 = """<tokengraphics>
                <tokenposition x="-9" y="-2"/>
                <unexpected/>
            </tokengraphics>"""
    n = @test_logs((:warn,"<tokengraphics> ignoring unexpected element 'unexpected'"),
                parse_tokengraphics(xmlroot(str1), pntd, registry()))
    @test n isa PNML.TokenGraphics
    @test length(n.positions) == 1

    str2 = """<tokengraphics>
                <tokenposition x="-9" y="-2"/>
                <tokenposition x="2"  y="3"/>
            </tokengraphics>"""
    n = parse_tokengraphics(xmlroot(str2), pntd, registry())
    @test n isa PNML.TokenGraphics
    @test length(n.positions) == 2

    str3 = """<tokengraphics>
                    <tokenposition x="-9.0" y="-2"/>
                    <tokenposition x="2.0"  y="3"/>
                    <tokenposition x="-2" y="2"/>
            </tokengraphics>"""
    n = parse_tokengraphics(xmlroot(str3), pntd, registry())
    @test n isa PNML.TokenGraphics
    @test length(n.positions) == 3
    #TODO test ordering
end
