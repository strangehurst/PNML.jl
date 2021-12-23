header("PARSE_LABELS")
@testset "declaration" begin
    reg = PNML.IDRegistry()
    n = parse_node(xml"""
        <declaration key="test">
          <structure>
           <declarations>
            <text> #TODO </text>
            <text key="bad"> yes really </text>
           </declarations>
          </structure>
        </declaration>
        """; reg)
    printnode(n)
    @test typeof(n) <: PNML.Declaration
    @test xmlnode(n) isa Maybe{EzXML.Node}

    @test typeof(n.d) <: PNML.PnmlDict
    @test n.d[:structure][:declarations][:text][1] == "#TODO"
    @test n.d[:structure][:declarations][:text][2] == "yes really"
end

@testset "initMarking" begin
    str = """
 <initialMarking>
     <graphics>
            <offset x="0" y="0"/>
     </graphics>
     <text>1</text>
 </initialMarking>
    """
    reg = PNML.IDRegistry()
    n = parse_node(to_node(str); reg)
    printnode(n)
    @test typeof(n) <: PNML.PTMarking
    @test xmlnode(n) isa Maybe{EzXML.Node}
    @test typeof(n.value) <: Number
    @test n.value == 1
end

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
    reg = PNML.IDRegistry()
    n = parse_node(to_node(str); reg)
    printnode(n)
    @test typeof(n) <: PNML.HLMarking
    @test xmlnode(n) isa Maybe{EzXML.Node}
    # 
    @test n.text == "<All,All>"
    @test n.structure !== nothing
    @test n.structure[:tuple][:subterm][1][:all] !== nothing
    @test n.structure[:tuple][:subterm][1][:all][:usersort][:declaration] == "N1"
    @test n.structure[:tuple][:subterm][2][:all][:usersort][:declaration] == "N2"
end

@testset "text" begin
    str1 = """
 <text>ready</text>
    """
    reg = PNML.IDRegistry()
    n = parse_node(to_node(str1); reg)
    @test n == "ready"
    
    str2 = """
 <text>
ready
</text>
    """
    n = parse_node(to_node(str2); reg)
    @test n == "ready"
    
    str3 = """
 <text>    ready  </text>
    """
    n = parse_node(to_node(str3); reg)
    @test n == "ready"
    
    str4 = """
     <text>ready
to
go</text>
    """
    n = parse_node(to_node(str4); reg)
    @test n == "ready\nto\ngo"
    
end

@testset "structure" begin
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
    reg = PNML.IDRegistry()
    n = parse_node(to_node(str); reg)
    printnode(n)
    @test tag(n) === :structure
    @test xmlnode(n) isa Maybe{EzXML.Node}

    @test n[:tuple][:subterm][1][:all][:usersort][:declaration] == "N1"
    @test n[:tuple][:subterm][2][:all][:usersort][:declaration] == "N2"
end

@testset "ref Trans" begin
    str = """
        <referenceTransition id="rt1" ref="t1"/>
    """
    reg = PNML.IDRegistry()
    n = parse_node(to_node(str); reg)
    printnode(n)
    @test typeof(n) <: PNML.RefTransition
    @test !PNML.has_xml(n) #xmlnode(n) isa Maybe{EzXML.Node}
    #@test haskey(n,:id)
    #@test haskey(n,:ref)
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
        reg = PNML.IDRegistry()
        n = parse_node(to_node(s); reg)
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
        reg = PNML.IDRegistry()
        n = parse_node(to_node(s); reg)
        printnode(n)
        @test haskey(n,:tag)
        @test tag(n) === :type
        @test n[:text] == "N2"
        @test n[:structure][:usersort][:declaration] == "N2"
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
        reg = PNML.IDRegistry()
        n = parse_node(to_node(s); reg)
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
        reg = PNML.IDRegistry()
        n = parse_node(to_node(s); reg)
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
        reg = PNML.IDRegistry()
        n = parse_node(to_node(s); reg)
        printnode(n)
        @test typeof(n) <: PNML.HLInscription
        @test xmlnode(n) isa Maybe{EzXML.Node}
        @test n.structure !== nothing
        @test n.text !== nothing
    end
end

