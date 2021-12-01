@testset "parse tools" begin
    str1 = """
 <toolspecific tool="JARP" version="1.2">
        <FrameColor>
          <value>java.awt.Color[r=0,g=0,b=0]</value>
        </FrameColor>
        <FillColor>
          <value>java.awt.Color[r=255,g=255,b=255]</value>
        </FillColor>
 </toolspecific>
"""
    str2 = """
 <toolspecific tool="de.uni-freiburg.telematik.editor" version="1.0">
     <visible>true</visible>
 </toolspecific>
"""
    str3 = """
 <toolspecific tool="petrinet" version="1.0">
     <placeCapacity capacity="0"/>
 </toolspecific>
"""
    str4 = """
 <toolspecific tool="petrinet" version="1.0">
    <tokengraphics>
         <tokenposition x="-9" y="-2"/>
         <tokenposition x="2"  y="3"/>
     </tokengraphics>
 </toolspecific>
"""
    str5 = """
 <toolspecific tool="petrinet" version="1.0">
    <tokengraphics>
         <tokenposition x="-9" y="-2"/>
         <tokenposition x="2"  y="3"/>
     </tokengraphics>
     <visible>true</visible>
 </toolspecific>
"""
    @testset for s in [str1, str2, str3, str4, str5] 
        n = parse_node(root(EzXML.parsexml(s)); reg=PNML.IDRegistry())
        printnode(n)
        @test tag(n) === :toolspecific
        @test xmlnode(n) isa Maybe{EzXML.Node}
        @test haskey(n, :tool)
        @test haskey(n, :version)
        @test haskey(n, :content)
        foreach(n[:content]) do c
            @test haskey(c, :tag)
            @test xmlnode(c) isa Maybe{EzXML.Node}
            if PRINT_PNML && haskey(c, :xml) && !isnothing(c[:xml])
                EzXML.prettyprint(c[:xml]);
                println()
            end
        end
    end
end
