header("TOOLSPECIFIC")
@testset "parse tools" begin
    str1 = (tool="JARP", version="1.2", str = """
 <toolspecific tool="JARP" version="1.2">
        <FrameColor>
          <value>java.awt.Color[r=0,g=0,b=0]</value>
        </FrameColor>
        <FillColor>
          <value>java.awt.Color[r=255,g=255,b=255]</value>
        </FillColor>
 </toolspecific>
""", contentparse = (c) -> begin end)

    str2 = (tool="de.uni-freiburg.telematik.editor", version="1.0", str = """
 <toolspecific tool="de.uni-freiburg.telematik.editor" version="1.0">
     <visible>true</visible>
 </toolspecific>
""", contentparse = (c) -> begin end)

    str3 = (tool="petrinet3", version="1.0", str = """
 <toolspecific tool="petrinet3" version="1.0">
     <placeCapacity capacity="0"/>
 </toolspecific>
""", contentparse = (c) -> begin end)

str4 = (tool="org.pnml.tool", version="1.0", str = """
 <toolspecific tool="org.pnml.tool" version="1.0">
    <tokengraphics>
         <tokenposition x="-9" y="-2"/>
         <tokenposition x="2"  y="3"/>
     </tokengraphics>
 </toolspecific>
""", contentparse = (c) -> begin end)

    str5 = (tool="org.pnml.tool", version="1.0", str = """
 <toolspecific tool="org.pnml.tool" version="1.0">
    <tokengraphics>
         <tokenposition x="-9" y="-2"/>
         <tokenposition x="2"  y="3"/>
     </tokengraphics>
     <visible>true</visible>
 </toolspecific>
""", contentparse = (c) -> begin end)

    @testset for s in [str1, str2, str3, str4, str5]
        @show s
        n = parse_node(root(EzXML.parsexml(s.str)); reg=PNML.IDRegistry())
        printnode(n)

        @test typeof(n) <: ToolInfo
        @test xmlnode(n) isa Maybe{EzXML.Node}
        #test_call xmlnode(n)
        @test n.toolname == s.tool
        @test name(n) == s.tool
        @test n.version == s.version
        @test version(n) == s.version

        @test get_toolinfo(n, s.tool, s.version) isa ToolInfo
        @test get_toolinfo(n, s.tool, s.version) == n # Is identity on scalar
        @test get_toolinfo(n, s.tool) == n
        @test get_toolinfo(n, s.tool, r"^.*$") == n
        @test get_toolinfo(n, Regex(s.tool), r"^.*$") == n
        @test get_toolinfo(n, Regex(s.tool)) == n

        #test_call get_toolinfo(n, s.tool, s.version)

        #s.contentparse(n.infos) #TODO
        # contentparse should handle a vector or scalar of well-formed xml.

        @test n.infos isa Vector{AnyElement}
        @test PNML.infos(n) isa Vector{AnyElement}
        foreach(n.infos) do toolinfo
            @test toolinfo isa AnyElement
            # Content may optionally attach its xml.
            @test !PNML.has_xml(toolinfo) || xmlnode(toolinfo) isa Maybe{EzXML.Node}
        end
        println()
    end
    @testset "combined" begin
        println("combined tools")
        str = """
<?xml version="1.0"?>
<pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
 <net id="net0" type="pnmlcore">
 <page id="page0">
 <place id="place0">
    $(str1.str)
    $(str2.str)
    $(str3.str)
    $(str4.str)
    $(str5.str)
 </place>
 </page>
 </net>
</pnml>
"""
        model = parse_str(str)
        @show model

        page = firstpage(first_net(model))
        #test_call firstpage(first_net(model))

        @test !has_tools(page)
        #test_call has_tools(page)

        place = first(page.places)
        @test has_tools(place)
        #test_call has_tools(place)
        t = tools(place)
        #test_call tools(place)
        @test t isa Vector{ToolInfo}
        @test length(t) == 5

        for ti in t
            @test ti isa ToolInfo
        end
        for (i,s) in enumerate([str1, str2, str3, str4, str5])
            ti = get_toolinfo(t, s.tool, s.version)
            @test ti isa ToolInfo
            @test PNML.name(t[i]) == PNML.name(ti)
            @test PNML.version(t[i]) == PNML.version(ti)
            @test PNML.name(t[i]) == s.tool
            @test PNML.version(t[i]) == s.version

            #test_call PNML.name(t[i])
            #test_call PNML.version(t[i])

            @test typeof(t[i].infos) == typeof(ti.infos)

            for y in zip(t[i].infos, ti.infos)
                @test tag(y[1]) == tag(y[2])
                @test y[1].dict == y[2].dict
            end

            x = parse_node(root(EzXML.parsexml(s.str)); reg=PNML.IDRegistry())

            @test typeof(t[i].infos) == typeof(x.infos)
            for y in zip(t[i].infos, x.infos)
                @test tag(y[1]) == tag(y[2])
                @test y[1].dict == y[2].dict
            end
        end
    end
end
