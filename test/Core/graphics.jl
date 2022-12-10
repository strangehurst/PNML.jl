using PNML, EzXML, ..TestUtils, JET
using PNML: tag, pid

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
    n = parse_node(xmlroot(str); reg=IDRegistry())

    @test n.offset isa PNML.Coordinate
    @test n.dimension isa PNML.Coordinate
    @test n.position isa Vector{PNML.Coordinate}

    @test_call PNML.Coordinate(1,2)
    @test_call PNML.Coordinate(1.1,2.2)

    # There can only be one offset, last tag parsed wins.
    @test n.offset == PNML.Coordinate(7,8)
    @test n.dimension == PNML.Coordinate(5,6)
    @test length(n.position) == 2
    @test n.position == [PNML.Coordinate(1,2), PNML.Coordinate(3,4)]

    @test n.line isa PNML.Line
    @test n.line.color == "linecolor"
    @test n.line.shape == "line"
    @test n.line.style == "solid"
    @test n.line.width == "1.0"

    @test n.fill isa PNML.Fill
    @test n.fill.color == "fillcolor"
    @test n.fill.image === nothing
    @test n.fill.gradient_color == "none"
    @test n.fill.gradient_rotation === "horizontal"

    @test n.font isa PNML.Font
    @test n.font.family == "Dialog"
    @test n.font.style == "normal"
    @test n.font.weight == "normal"
    @test n.font.size == "11"
    @test n.font.decoration === nothing
    @test n.font.align == "center"
    @test n.font.rotation == "0.0"
end


@testset "tokengraphics" begin
    str0 = """
 <tokengraphics>
 </tokengraphics>
"""
    str1 = """
 <tokengraphics>
     <tokenposition x="-9" y="-2"/>
 </tokengraphics>
"""
    str2 = """
 <tokengraphics>
     <tokenposition x="-9" y="-2"/>
     <tokenposition x="2"  y="3"/>
 </tokengraphics>
"""
    str3 = """
 <tokengraphics>
     <tokenposition x="-9" y="-2"/>
     <tokenposition x="2"  y="3"/>
     <tokenposition x="-2" y="2"/>
 </tokengraphics>
"""
    str4 = """
 <tokengraphics>
     <tokenposition x="-9" y="-2"/>
     <tokenposition x="2"  y="3"/>
     <tokenposition x="-2" y="2"/>
     <tokenposition x="-2" y="-22"/>
 </tokengraphics>
"""
    str5 = """
 <tokengraphics>
     <tokenposition x="-1.2" y="-22.33"/>
 </tokengraphics>
"""
    str6 = """
 <tokengraphics>
     <tokenposition x="-1" y="-2"/>
     <tokenposition x="-1.2" y="-22.33"/>
 </tokengraphics>
"""
    @testset "tokengraphics $l tokenpositions" for (s,l) in [str0=>0,
                                                             str1=>1,
                                                             str2=>2,
                                                             str3=>3,
                                                             str4=>4,
                                                             str5=>1,
                                                             str6=>2]
        n = parse_node(xmlroot(s); reg=IDRegistry())
        @test n isa PNML.TokenGraphics
        @test length(n.positions) == l
    end
end
