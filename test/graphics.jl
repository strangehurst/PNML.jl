
@testset "graphics" begin
    str = """
    <graphics>
     <offset x="1" y="2" />
     <line  color="linecolor" shape="line" style="solid" width="1.0"/>
     <position  x="1" y="2" />
     <position  x="3" y="4" />
     <dimension x="5" y="6" />
     <offset    x="7" y="8" /><!-- override first offset -->
     <fill  color="fillcolor" gradient-color="none" />
     <font align="center" family="Dialog" rotation="0.0" size="11"
           style="normal" weight="normal"/>
    </graphics>
    """
    doc = EzXML.parsexml(str)
    n = parse_node(root(doc); reg=PNML.IDRegistry())
    printnode(n)
    @test n[:tag] == :graphics
    @test isnothing(n[:xml]) || n[:xml] isa EzXML.Node
    @test haskey(n,:offset)
    @test haskey(n,:line)
    @test haskey(n,:positions)
    @test haskey(n,:dimension)
    @test haskey(n,:fill)
    @test haskey(n,:font)

    # There can only be one offset, last tag parsed wins.
    @test n[:offset][:x] == 7
    @test n[:offset][:y] == 8
    @test n[:line][:color] == "linecolor"
    @test n[:line][:shape] == "line"
    @test n[:line][:style] == "solid"
    @test n[:line][:width] == "1.0"
    @test n[:dimension][:x] == 5
    @test n[:dimension][:y] == 6
    @test n[:fill][:color] == "fillcolor"
    @test n[:fill][:image] === nothing
    @test n[:fill][:gradient_color] == "none"
    @test n[:fill][:gradient_rotation] === nothing
    @test n[:font][:family] == "Dialog"
    @test n[:font][:style] == "normal"
    @test n[:font][:weight] == "normal"
    @test n[:font][:size] == "11"
    @test n[:font][:decoration] === nothing
    @test n[:font][:align] == "center"
    @test n[:font][:rotation] == "0.0"

    # There can be multiple position tags. Parsed as a vector
    @test n[:positions] isa Vector{PNML.PnmlDict}
    @test length(n[:positions]) == 2
    @test n[:positions][1][:x] == 1
    @test n[:positions][1][:y] == 2
    @test n[:positions][2][:x] == 3
    @test n[:positions][2][:y] == 4
end


@testset "tokencolors" begin
    str1 = """
 <tokencolors>
      <tokencolor>
        <color>red</color>
        <rgbcolor>
          <r>246</r>
          <g>5</g>
          <b>5</b>
        </rgbcolor>
      </tokencolor>
 </tokencolors>
"""
    @testset for s in [str1] #, str2, str3] 
        d = PNML.PnmlDict(:labels=>[])
        n = PNML.add_label!(d, root(EzXML.parsexml(s)); reg=PNML.IDRegistry())
        printnode(d)
        @test haskey(d,:labels)
        @test d[:labels] == n
        @test length(d[:labels]) == 1
        foreach(d[:labels]) do l
            @test l[:tag] == :tokencolors
            @test isnothing(l[:xml]) || l[:xml] isa EzXML.Node
        end
    end
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
    @testset for (s,l) in [str0=>0, str1=>1, str2=>2, str3=>3, str4=>4]
        n = parse_node(root(EzXML.parsexml(s)); reg=PNML.IDRegistry())
        printnode(n)
        @test n[:tag] == :tokengraphics
        @test haskey(n,:positions)
        @test length(n[:positions]) == l
        @test isnothing(n[:xml]) || n[:xml] isa EzXML.Node
    end
end
