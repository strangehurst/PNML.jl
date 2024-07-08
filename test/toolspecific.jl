using PNML, EzXML, ..TestUtils, JET

using OrderedCollections

#const idregistry = ScopedValue{PnmlIDRegistry}()

str1 = (tool="JARP", version="1.2",
        str = """
 <toolspecific tool="JARP" version="1.2">
    <FrameColor><value>java.awt.Color[r=0,g=0,b=0]</value></FrameColor>
    <FillColor><value>java.awt.Color[r=255,g=255,b=255]</value></FillColor>
 </toolspecific>
""")

str2 = (tool="de.uni-freiburg.telematik.editor", version="1.0",
        str = """
 <toolspecific tool="de.uni-freiburg.telematik.editor" version="1.0">
    <visible>true</visible>
 </toolspecific>
""")

str3 = (tool="petrinet3", version="1.0",
        str = """
 <toolspecific tool="petrinet3" version="1.0">
    <placeCapacity capacity="0"/>
 </toolspecific>
""")

str4 = (tool="org.pnml.tool", version="1.0",
        str = """
 <toolspecific tool="org.pnml.tool" version="1.0">
    <tokengraphics>
         <tokenposition x="-9" y="-2"/>
         <tokenposition x="2"  y="3"/>
     </tokengraphics>
 </toolspecific>
""")

str5 = (tool="org.pnml.tool", version="1.0",
        str = """
 <toolspecific tool="org.pnml.tool" version="1.0">
    <tokengraphics>
         <tokenposition x="-9" y="-2"/>
         <tokenposition x="2"  y="3"/>
     </tokengraphics>
     <visible>true</visible>
 </toolspecific>
""")

@testset "parse tool $(s.tool) $(s.version)" for s in [str1, str2, str3, str4, str5]
        tooli = parse_toolspecific(xmlroot(s.str), PnmlCoreNet())

        @test isa(tooli, ToolInfo)
        @test name(tooli) == s.tool
        @test PNML.version(tooli) == s.version

        @test get_toolinfo(tooli, s.tool, s.version) == tooli # Is identity on scalar
        @test get_toolinfo(tooli, s.tool) == tooli
        @test get_toolinfo(tooli, s.tool, r"^.*$") == tooli
        @test get_toolinfo(tooli, Regex(s.tool), r"^.*$") == tooli
        @test get_toolinfo(tooli, Regex(s.tool)) == tooli

        @test_call broken=false get_toolinfo(tooli, s.tool, s.version)
end

@testset "combined tools" begin
    empty!(PNML.TOPDECLDICTIONARY)
    dd = PNML.TOPDECLDICTIONARY[:nothing] = PNML.DeclDict()
    PNML.fill_nonhl!(dd; ids=(:nothing,))
    #@show dd

    n::XMLNode = xmlroot(
        """<place id="place0">
        $(str1.str)
        $(str2.str)
        $(str3.str)
        $(str4.str)
        $(str5.str)
        <initialMarking> <text>5</text> </initialMarking>
        </place>
        """)

    combinedplace = @with PNML.idregistry=>registry() parse_place(n, PnmlCoreNet(); ids=(:nothing,))

    @test_call tools(combinedplace)
    placetools = tools(combinedplace)
    @test length(placetools) == 5
    @test all(t -> isa(t, ToolInfo), placetools)

    @test PNML.has_toolinfo(placetools, r"petrinet3", r"1\.*")
    @test PNML.has_toolinfo(placetools, "petrinet3", "1.0")
    @test PNML.has_toolinfo(placetools, "petrinet3")
    @test !PNML.has_toolinfo(placetools, "XXX")
    @test !PNML.has_toolinfo(placetools, "petrinet3", "2.0")
    # Assumes ordered collection.
    for (i,s) in enumerate([str1, str2, str3, str4, str5])
        ti = get_toolinfo(placetools, s.tool, s.version)
        @test ti isa ToolInfo
        @test PNML.name(placetools[i])    == PNML.name(ti) == s.tool
        @test PNML.version(placetools[i]) == PNML.version(ti) == s.version
        @test_call PNML.name(placetools[i])
        @test_call PNML.version(placetools[i])
        @test typeof(placetools[i].infos) == typeof(ti.infos)
    end
end
