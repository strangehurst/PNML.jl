using PNML, EzXML, ..TestUtils, JET
using PNML: Maybe, tag, pid, XMLNode,
    ToolInfo, AnyElement, name, version, get_toolinfo, first_net, firstpage,
    tools, parse_toolspecific, place, parse_place, TokenGraphics,
    coordinate_value_type
using OrderedCollections

str1 = (tool="JARP", version="1.2", str = """
 <toolspecific tool="JARP" version="1.2">
        <FrameColor>
          <value>java.awt.Color[r=0,g=0,b=0]</value>
        </FrameColor>
        <FillColor>
          <value>java.awt.Color[r=255,g=255,b=255]</value>
        </FillColor>
 </toolspecific>
""", elementtype = OrderedDict{Union{Symbol,String}, Any}) #! Vector{AnyElement})

str2 = (tool="de.uni-freiburg.telematik.editor", version="1.0", str = """
 <toolspecific tool="de.uni-freiburg.telematik.editor" version="1.0">
     <visible>true</visible>
 </toolspecific>
""", elementtype = OrderedDict{Union{Symbol,String}, Any}) #! Vector{AnyElement})

str3 = (tool="petrinet3", version="1.0", str = """
 <toolspecific tool="petrinet3" version="1.0">
     <placeCapacity capacity="0"/>
 </toolspecific>
""", elementtype = OrderedDict{Union{Symbol,String}, Any}) #! Vector{AnyElement})

str4 = (tool="org.pnml.tool", version="1.0", str = """
 <toolspecific tool="org.pnml.tool" version="1.0">
    <tokengraphics>
         <tokenposition x="-9" y="-2"/>
         <tokenposition x="2"  y="3"/>
     </tokengraphics>
 </toolspecific>
""", elementtype = TokenGraphics{coordinate_value_type()})

str5 = (tool="org.pnml.tool", version="1.0", str = """
 <toolspecific tool="org.pnml.tool" version="1.0">
    <tokengraphics>
         <tokenposition x="-9" y="-2"/>
         <tokenposition x="2"  y="3"/>
     </tokengraphics>
     <visible>true</visible>
 </toolspecific>
""", elementtype = TokenGraphics{coordinate_value_type()})

@testset "parse tools" begin
    for s in [str1, str2, str3, str4, str5]
        tooli = parse_toolspecific(xmlroot(s.str), PnmlCoreNet(), registry())
        @test isa(tooli, ToolInfo)
        @test name(tooli) == s.tool
        @test version(tooli) == s.version

        @test get_toolinfo(tooli, s.tool, s.version) isa ToolInfo
        @test get_toolinfo(tooli, s.tool, s.version) == tooli # Is identity on scalar
        @test get_toolinfo(tooli, s.tool) == tooli
        @test get_toolinfo(tooli, s.tool, r"^.*$") == tooli
        @test get_toolinfo(tooli, Regex(s.tool), r"^.*$") == tooli
        @test get_toolinfo(tooli, Regex(s.tool)) == tooli

        @test_call broken=false get_toolinfo(tooli, s.tool, s.version)

        #!@test tooli.infos isa s.elementtype
        #!@test PNML.infos(tooli) isa s.elementtype
        #!Base.redirect_stdio(stdout=testshow, stderr=testshow) do; end
    end
    @testset "combined" begin
        str = """<place id="place0">
        $(str1.str)
        $(str2.str)
        $(str3.str)
        $(str4.str)
        $(str5.str)
        </place>
        """
        n::XMLNode = xmlroot(str)
        p0 = parse_place(n, PnmlCoreNet(), registry())

        t = tools(p0)
        @test_call tools(p0)
        @test t isa Vector{ToolInfo}
        @test length(t) == 5

        for ti in t
            @test ti isa ToolInfo
        end

        @test PNML.has_toolinfo(t, r"petrinet3", r"1\.*")
        @test PNML.has_toolinfo(t, "petrinet3", "1.0")
        @test PNML.has_toolinfo(t, "petrinet3")
        @test !PNML.has_toolinfo(t, "XXX")
        @test !PNML.has_toolinfo(t, "petrinet3", "2.0")

        for (i,s) in enumerate([str1, str2, str3, str4, str5])
            ti = get_toolinfo(t, s.tool, s.version)
            @test ti isa ToolInfo
            @test PNML.name(t[i]) == PNML.name(ti)
            @test PNML.version(t[i]) == PNML.version(ti)
            @test PNML.name(t[i]) == s.tool
            @test PNML.version(t[i]) == s.version

            @test_call PNML.name(t[i])
            @test_call PNML.version(t[i])

            @test typeof(t[i].infos) == typeof(ti.infos)
        end
    end
end
