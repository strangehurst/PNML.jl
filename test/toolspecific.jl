using PNML, ..TestUtils, JET

using OrderedCollections

str1 = (tool="JARP", version="1.2", str = """
<toolspecific tool="JARP" version="1.2">
    <FrameColor><value>java.awt.Color[r=0,g=0,b=0]</value></FrameColor>
    <FillColor><value>java.awt.Color[r=255,g=255,b=255]</value></FillColor>
</toolspecific>
""")

str2 = (tool="de.uni-freiburg.telematik.editor", version="1.0", str = """
<toolspecific tool="de.uni-freiburg.telematik.editor" version="1.0">
    <visible>true</visible>
</toolspecific>
""")

str3 = (tool="petrinet3", version="1.0", str = """
<toolspecific tool="petrinet3" version="1.0">
    <placeCapacity capacity="0"/>
</toolspecific>
""")

str4 = (tool="org.pnml.tool", version="1.0", str = """
 <toolspecific tool="org.pnml.tool" version="1.0">
    <tokengraphics>
         <tokenposition x="-9" y="-2"/>
         <tokenposition x="2"  y="3"/>
     </tokengraphics>
 </toolspecific>
""")

#TODO! NUPN API
# located either inside the "net" element or inside the (supposedly unique) "page" element of the PNML file.
#
str5 = (tool="nupn", version="1.1", str = """
<toolspecific tool="nupn" version="1.1">
    <size places="1" transitions="1" arcs="1"/>
    <structure units="2" root="u0" safe="false"/>
    <unit id="u0">
        <places/>
        <subunits>u1</subunits>
    </unit>
    <unit id="u1">
        <places>p1</places>
        <subunits/>
    </unit>
</toolspecific>
""")

str6 = (tool="WoPeD", version="1.0", str = """
<toolspecific version="1.0" tool="WoPeD">
    <!-- there are empty toolinfos in the examples -->
</toolspecific>
""")

str7 = (tool="WoPeD", version="1.0", str = """
<toolspecific version="1.0" tool="WoPeD">
    <trigger type="200" id="">
        <graphics>
            <position y="30" x="290" />
            <dimension y="22" x="24" />
        </graphics>
    </trigger>
    <operator type="105" id="t14" />
    <time>0</time>
    <timeUnit>1</timeUnit>
</toolspecific>
""")

#-----------------------------------------------------------------------------------
@testset "parse tool specific info $(s.tool) $(s.version)" for s in [str1, str2, str3, str4, str5]
    println("\n###### parse tool $(s.tool) $(s.version)")
    @show tooli = parse_toolspecific(xmlroot(s.str), PnmlCoreNet())

    @test isa(tooli, ToolInfo)
    @test name(tooli) == s.tool
    @test PNML.Labels.version(tooli) == s.version

    @test get_toolinfo([tooli], s.tool, s.version) == tooli # Is identity on scalar
    @test get_toolinfo([tooli], s.tool) == tooli
    @test get_toolinfo([tooli], s.tool, r"^.*$") == tooli
    @test get_toolinfo([tooli], Regex(s.tool), r"^.*$") == tooli
    @test get_toolinfo([tooli], Regex(s.tool)) == tooli

    @test_call broken=false get_toolinfo([tooli], s.tool, s.version)
end

@testset "combined tools" begin
    @with PNML.idregistry => PnmlIDRegistry() PNML.DECLDICT => PNML.DeclDict() begin
        PNML.fill_nonhl!(PNML.DECLDICT[])
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

        combinedplace = parse_place(n, PnmlCoreNet())

        @test_call tools(combinedplace)
        @show placetools = tools(combinedplace)
        @test length(placetools) == 5
        @test all(t -> isa(t, ToolInfo), placetools)

        @test has_toolinfo(placetools, r"petrinet3", r"1\.*")
        @test has_toolinfo(placetools, "petrinet3", "1.0")
        @test has_toolinfo(placetools, "petrinet3")
        @test !has_toolinfo(placetools, "XXX")
        @test !has_toolinfo(placetools, "petrinet3", "2.0")
        # Assumes ordered collection.
        for (i,s) in enumerate([str1, str2, str3, str4, str5])
            ti = get_toolinfo(placetools, s.tool, s.version)
            @test ti isa ToolInfo
            @test PNML.name(placetools[i])    == PNML.name(ti) == s.tool
            @test PNML.Labels.version(placetools[i]) == PNML.Labels.version(ti) == s.version
            @test_call PNML.name(placetools[i])
            @test_call PNML.Labels.version(placetools[i])
            @test typeof(placetools[i].infos) == typeof(ti.infos)
        end
    end
end
