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
  
        n = parse_node(root(EzXML.parsexml(s.str)); reg=PNML.IDRegistry())
        printnode(n)
        @test typeof(n) <: PNML.ToolInfo
        @test xmlnode(n) isa Maybe{EzXML.Node}
        @test n.toolname == s.tool
        @test n.version == s.version
        
        @show n.info
        #s.contentparse(n.info) #TODO
        # contentparse should handle a vector or scalar of well-formed xml.
        foreach(n.info) do toolinfo
            @show toolinfo
            # Content may optionally attach its xml.            
            @test !PNML.has_xml(toolinfo) || xmlnode(toolinfo) isa Maybe{EzXML.Node}
        end
    end
end
