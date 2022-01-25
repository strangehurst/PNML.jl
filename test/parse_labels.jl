header("PARSE_LABELS")

header("UNCLAIMED ELEMENT")
@testset "attribute" begin
    # pnml attribute XML nodes do not have display/GUI data and other
    # overhead of pnml annotation nodes. Both are pnml labels.
    a = PNML.unclaimed_element(xml"""
                           <declarations atag="test">
                                <something> some content </something>
                                <something2 tag2="two"> <value/> </something2>
                           </declarations>
                        """; reg=PNML.IDRegistry())
    printnode(a, type=true)
    @test !isnothing(a)
end

header("DECLARATION")
@testset "declaration" begin
    n = parse_node(xml"""
        <declaration key="test">
          <structure>
           <declarations>
            <text> #TODO </text>
            <text key="bad"> yes really </text>
           </declarations>
          </structure>
        </declaration>
        """; reg= PNML.IDRegistry())
    printnode(n)
    
    @test typeof(n) <: PNML.Declaration 
    @test xmlnode(n) isa Maybe{EzXML.Node}

    @show typeof(n), fieldnames(typeof(n))
    @show typeof(n.d), fieldnames(typeof(n.d))
    for (k,v) in pairs(n.d.dict)
        @show k, typeof(v), v
    end

    @test typeof(n.d) <: PNML.PnmlLabel

    @show typeof(n.d.dict)
    @show typeof(n.d.dict[:structure])
    @show typeof(n.d.dict[:structure].dict)
    @show typeof(n.d.dict[:structure].dict[:declarations])

    @test n.d.dict[:tag] === :declaration
    @test n.d.dict[:key] == "test"

    @show n.d.dict[:structure].dict
    @show n.d.dict[:structure].dict[:declarations].dict[:text]

    @test n.d.dict[:structure].dict[:declarations].dict[:text][1] == "#TODO"
    @test n.d.dict[:structure].dict[:declarations].dict[:text][2] == "yes really"
    println()
end

header("PT initMarking")
@testset "PT initMarking" begin
    str = """
 <initialMarking>
    <!-- not valid here <graphics> <offset x="0" y="0"/> </graphics> -->
    <text>1</text>
    <toolspecific tool="org.pnml.tool" version="1.0">
        <tokengraphics>
            <tokenposition x="6" y="9"/>
        </tokengraphics>
    </toolspecific>
 </initialMarking>
    """

    n = parse_node(to_node(str); reg=PNML.IDRegistry())
    printnode(n)
    @test typeof(n) <: PNML.PTMarking
    @test xmlnode(n) isa Maybe{EzXML.Node}
    @test typeof(n.value) <: Number
    @test n.value == 1
end

header("HL Marking")
@testset "HL initMarking" begin
    str = """
 <hlinitialMarking>
     <text>&lt;All,All&gt;</text>
     <structure>
            <tuple>
              <subterm>
                <all>
                  <usersort declaration="N1"/>
                </all>
              </subterm>
              <subterm>
                <all>
                  <usersort declaration="N2"/>
                </all>
              </subterm>
            </tuple>
     </structure>
 </hlinitialMarking>
    """
    n = parse_node(to_node(str); reg = PNML.IDRegistry())
    printnode(n)
    @test typeof(n) <: PNML.AbstractLabel
    @test typeof(n) <: PNML.HLMarking
    @test xmlnode(n) isa Maybe{EzXML.Node}
    @test n.text == "<All,All>"
    @test n.structure !== nothing
    @test n.structure.dict[:tuple].dict[:subterm][1].dict[:all] !== nothing
    @test n.structure.dict[:tuple].dict[:subterm][1].dict[:all].dict[:usersort].dict[:declaration] == "N1"
    @test n.structure.dict[:tuple].dict[:subterm][2].dict[:all].dict[:usersort].dict[:declaration] == "N2"
end

@testset "text" begin
    str1 = """
 <text>ready</text>
    """
    n = parse_node(to_node(str1); reg = PNML.IDRegistry())
    @test n == "ready"
    
    str2 = """
 <text>
ready
</text>
    """
    n = parse_node(to_node(str2); reg = PNML.IDRegistry())
    @test n == "ready"
    
    str3 = """
 <text>    ready  </text>
    """
    n = parse_node(to_node(str3); reg = PNML.IDRegistry())
    @test n == "ready"
    
    str4 = """
     <text>ready
to
go</text>
    """
    n = parse_node(to_node(str4); reg = PNML.IDRegistry())
    @test n == "ready\nto\ngo"    
end

@testset "structure" begin
    header("STRUCTURE")
    str = """
     <structure>
         <tuple>
              <subterm>
                <all>
                  <usersort declaration="N1"/>
                </all>
              </subterm>
              <subterm>
                <all>
                  <usersort declaration="N2"/>
                </all>
              </subterm>
         </tuple>
     </structure>
    """

    n = parse_node(to_node(str); reg = PNML.IDRegistry())
    printnode(n)
    @test xmlnode(n) isa Maybe{EzXML.Node}

    @test n.dict[:tuple].dict[:subterm][1].dict[:all].dict[:usersort].dict[:declaration] == "N1"
    @test n.dict[:tuple].dict[:subterm][2].dict[:all].dict[:usersort].dict[:declaration] == "N2"
end

@testset "ref Trans" begin
    str = """
        <referenceTransition id="rt1" ref="t1"/>
    """
    n = parse_node(to_node(str); reg = PNML.IDRegistry())
    printnode(n)
    @test typeof(n) <: PNML.RefTransition
    @test !PNML.has_xml(n) #xmlnode(n) isa Maybe{EzXML.Node}
    @test pid(n) == :rt1
    @test n.ref == :t1
end

@testset "ref Place" begin
    str1 = """
 <referencePlace id="rp2" ref="rp1"/>
"""
    str2 = """
 <referencePlace id="rp1" ref="Sync1">
        <graphics>
          <position x="734.5" y="41.5"/>
          <dimension x="40.0" y="40.0"/>
        </graphics>
 </referencePlace>
"""
    @testset for s in [str1, str2] 
        n = parse_node(to_node(s); reg = PNML.IDRegistry())
        printnode(n)
        @test typeof(n) <: PNML.RefPlace
        @test !PNML.has_xml(n)
        @test typeof(n.id) == Symbol
        @test typeof(n.ref) == Symbol
    end
end

@testset "type" begin
    str1 = """
 <type>
     <text>N2</text>
     <structure>
            <usersort declaration="N2"/>
     </structure>
 </type>
    """
    @testset for s in [str1] 
        n = parse_node(to_node(s); reg = PNML.IDRegistry())
        printnode(n)
        @test typeof(n) <: PNML.PnmlLabel
        @test n.dict[:text] == "N2"
        @test n.dict[:structure].dict[:usersort].dict[:declaration] == "N2"
    end
end


@testset "condition" begin
    str1 = """
 <condition>
     <text>(x==1 and y==1 and d==1)</text>
     <structure>
            <or>
    #TODO
           </or>
     </structure>
 </condition>
    """
    @testset for s in [str1] 
        n = parse_node(to_node(s); reg = PNML.IDRegistry())
        printnode(n)
        @test typeof(n) <: PNML.Condition
        @test xmlnode(n) isa Maybe{EzXML.Node}
        @test n.structure !== nothing
        @test xmlnode(n.structure) isa Maybe{EzXML.Node}
        @test n.com.graphics === nothing
        @test !isempty(n.text)
        @test n.com.tools === nothing || isempty(n.com.tools)
        @test n.com.labels === nothing || isempty(n.com.labels)
    end
end

@testset "inscription" begin
    str1 = """
        <inscription> <text>12 </text> </inscription>
    """
    @testset for s in [str1] 
        n = parse_node(to_node(s); reg = PNML.IDRegistry())
        printnode(n)
        @test typeof(n) <: PNML.PTInscription
        @test xmlnode(n) isa Maybe{EzXML.Node}
        @test n.value == 12
        @test n.com.graphics === nothing
        @test n.com.tools === nothing || isempty(n.com.tools)
        @test n.com.labels === nothing || isempty(n.com.labels)
    end
end

@testset "hlinscription" begin
    str1 = """
 <hlinscription>
     <text>&lt;x,v&gt;</text>
     <structure>
            <tuple>
              <subterm>
                <variable refvariable="x"/>
              </subterm>
              <subterm>
                <variable refvariable="v"/>
              </subterm>
            </tuple>
     </structure>
 </hlinscription>
 """
    @testset for s in [str1] 
        n = parse_node(to_node(s); reg = PNML.IDRegistry())
        printnode(n)
        @test typeof(n) <: PNML.HLInscription
        @test xmlnode(n) isa Maybe{EzXML.Node}
        @test n.structure !== nothing
        @test n.text !== nothing
    end
end

