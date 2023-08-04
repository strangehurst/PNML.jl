using PNML, EzXML, ..TestUtils, JET
using PNML: tag, pid, parse_graphics, parse_tokengraphics

const _pntd::PnmlType = PnmlCoreNet()
@testset "coordinate" begin
    @test_opt PNML.Coordinate(1,2)
    @test_call PNML.Coordinate(1,2)
    @test_opt PNML.Coordinate(1.1,2.2)
    @test_call PNML.Coordinate(1.1,2.2)
end

@testset "graphics" begin
    str = """
    <graphics>
     <offset x="1" y="2" />
     <line  color="linecolor" shape="line" style="solid" width="1.0"/>
     <position  x="1" y="2" />
     <position  x="3" y="4" />
     <dimension x="5" y="6" />
     <offset    x="7" y="8" /><!-- override first offset -->
     <fill  color="fillcolor" gradient-color="none" gradient-rotation="horizontal"/>
     <font align="center" family="Dialog" rotation="0.0" size="11"
           style="normal" weight="normal" />
    </graphics>
    """
    n = parse_graphics(xmlroot(str), _pntd, registry())

    @test n.offset isa PNML.Coordinate
    @test n.dimension isa PNML.Coordinate
    @test n.positions isa Vector{PNML.Coordinate{Int}}
    Base.redirect_stdio(stdout=testshow, stderr=testshow) do;
        @show n
    end

    # There can only be one offset, last tag parsed wins.
    @test n.offset == PNML.Coordinate(7,8)
    @test n.dimension == PNML.Coordinate(5,6)
    @test length(n.positions) == 2
    @test n.positions == [PNML.Coordinate(1,2), PNML.Coordinate(3,4)]

    @test n.line isa PNML.Line
    @test n.line.color == "linecolor"
    @test n.line.shape == "line"
    @test n.line.style == "solid"
    @test n.line.width == "1.0"

    @test n.fill isa PNML.Fill
    @test n.fill.color == "fillcolor"
    @test isempty(n.fill.image) # === nothing
    @test n.fill.gradient_color == "none"
    @test n.fill.gradient_rotation === "horizontal"

    @test n.font isa PNML.Font
    @test n.font.family == "Dialog"
    @test n.font.style == "normal"
    @test n.font.weight == "normal"
    @test n.font.size == "11"
    @test isempty(n.font.decoration) # === nothing
    @test n.font.align == "center"
    @test n.font.rotation == "0.0"
end


@testset "graphics exception" begin
    str0 = """<bogus x="1" y="2" />"""

    @test_throws ArgumentError PNML.parse_graphics_coordinate(xmlroot(str0),  _pntd, registry())
end


@testset "tokengraphics" begin
    str0 = """<tokengraphics></tokengraphics>"""
    n = parse_tokengraphics(xmlroot(str0), _pntd, registry())
    @test n isa PNML.TokenGraphics
    @test length(n.positions) == 0

    str1 = """<tokengraphics>
                <tokenposition x="-9" y="-2"/>
            </tokengraphics>"""
    n = parse_tokengraphics(xmlroot(str1), _pntd, registry())
    @test n isa PNML.TokenGraphics
    @test length(n.positions) == 1

    str2 = """<tokengraphics>
                <tokenposition x="-9" y="-2"/>
                <tokenposition x="2"  y="3"/>
            </tokengraphics>"""
    n = parse_tokengraphics(xmlroot(str2), _pntd, registry())
    @test n isa PNML.TokenGraphics
    @test length(n.positions) == 2

    str3 = """<tokengraphics>
                    <tokenposition x="-9" y="-2"/>
                    <tokenposition x="2"  y="3"/>
                    <tokenposition x="-2" y="2"/>
            </tokengraphics>"""
    n = parse_tokengraphics(xmlroot(str3), _pntd, registry())
    @test n isa PNML.TokenGraphics
    @test length(n.positions) == 3

    str4 = """<tokengraphics>
                    <tokenposition x="-9" y="-2"/>
                    <tokenposition x="2"  y="3"/>
                    <tokenposition x="-2" y="2"/>
                    <tokenposition x="-2" y="-22"/>
            </tokengraphics>"""
    n = parse_tokengraphics(xmlroot(str4), _pntd, registry())
    @test n isa PNML.TokenGraphics
    @test length(n.positions) == 4

    str5 = """<tokengraphics>
                    <tokenposition x="-1.2" y="-22.33"/>
            </tokengraphics>"""
    n = parse_tokengraphics(xmlroot(str5), ContinuousNet(), registry())
    @test n isa PNML.TokenGraphics
    @test length(n.positions) == 1

    str6 = """<tokengraphics>
                    <tokenposition x="-1" y="-2"/>
                    <tokenposition x="-1.2" y="-22.33"/>
            </tokengraphics>"""
    n = parse_tokengraphics(xmlroot(str6), ContinuousNet(), registry()) # hubrid?
    @test n isa PNML.TokenGraphics
    @test length(n.positions) == 2
end
