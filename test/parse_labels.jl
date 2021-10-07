
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
        """)
    printnode(n)
    @test n[:tag] == :declaration
    @test isnothing(n[:xml]) ||  n[:xml] isa EzXML.Node
    @test haskey(n,:structure)
    @test haskey(n[:structure],:declarations)
    @test haskey(n[:structure][:declarations],:text)

    @test n[:structure][:declarations][:text][1][:content] == "#TODO"
    @test n[:structure][:declarations][:text][2][:content] == "yes really"
    #@test n[:structure][:declarations][:text][2][:key] == "bad"
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
    n = parse_node(to_node(str))
    printnode(n)
    @test n[:tag] == :initialMarking
    @test isnothing(n[:xml]) ||  n[:xml] isa EzXML.Node
    @test haskey(n,:value)
    @test n[:value] isa Int
    @test n[:value] == 1
    @test n[:structure] === nothing
    @test n[:text] === nothing
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
    n = parse_node(to_node(str))
    printnode(n)
    @test n[:tag] == :hlinitialMarking
    @test isnothing(n[:xml]) ||  n[:xml] isa EzXML.Node
    @test n[:text] !== nothing
    @test n[:text][:content] == "<All,All>"
    @test n[:structure] !== nothing
    @test n[:structure][:tuple][:subterm][1][:all] !== nothing
    @test n[:structure][:tuple][:subterm][1][:all][:usersort][:declaration] == "N1"
    @test n[:structure][:tuple][:subterm][2][:all][:usersort][:declaration] == "N2"
end

@testset "text" begin
    str1 = """
 <text>ready</text>
    """
    n = parse_node(to_node(str1))
    @test n[:content] == "ready"
    
    str2 = """
 <text>
ready
</text>
    """
    n = parse_node(to_node(str2))
    @test n[:content] == "ready"
    
    str3 = """
 <text>    ready  </text>
    """
    n = parse_node(to_node(str3))
    @test n[:content] == "ready"
    
    str4 = """
     <text>ready
to
go</text>
    """
    n = parse_node(to_node(str4))
    @test n[:content] == "ready\nto\ngo"
    
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
    n = parse_node(to_node(str))
    printnode(n)
    @test n[:tag] == :structure
    @test isnothing(n[:xml]) ||  n[:xml] isa EzXML.Node

    @test n[:tuple][:subterm][1][:all][:usersort][:declaration] == "N1"
    @test n[:tuple][:subterm][2][:all][:usersort][:declaration] == "N2"
end

@testset "ref Trans" begin
    str = """
        <referenceTransition id="rt1" ref="t1"/>
    """
    n = parse_node(to_node(str))
    printnode(n)
    @test n[:tag] == :referenceTransition
    @test isnothing(n[:xml]) ||  n[:xml] isa EzXML.Node
    @test haskey(n,:id)
    @test haskey(n,:ref)
    @test n[:id] == :rt1
    @test n[:ref] == :t1
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
        n = parse_node(to_node(s))
        printnode(n)
        @test n[:tag] == :referencePlace
        @test isnothing(n[:xml]) ||  n[:xml] isa EzXML.Node
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
        n = parse_node(to_node(s))
        printnode(n)
        @test haskey(n,:tag)
        @test n[:tag] == :type
        @test n[:text][:content] == "N2"
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
        n = parse_node(to_node(s))
        printnode(n)
        @test n[:tag] == :condition
        @test isnothing(n[:xml]) ||  n[:xml] isa EzXML.Node
        @test n[:structure] !== nothing
        @test isnothing(n[:structure][:xml]) || n[:structure][:xml] isa EzXML.Node
        @test n[:graphics] === nothing
        @test !isempty(n[:text])
        @test haskey(n,:tools)
        @test n[:tools] === nothing || isempty(n[:tools])
        @test haskey(n,:labels)
        @test n[:labels] === nothing || isempty(n[:labels])
    end
end

@testset "inscription" begin
    str1 = """
        <inscription> <text>12 </text> </inscription>
    """
    @testset for s in [str1] 
        n = parse_node(to_node(s))
        printnode(n)
        @test n[:tag] == :inscription
        @test isnothing(n[:xml]) ||  n[:xml] isa EzXML.Node
        @test n[:value] == 12
        @test n[:structure] === nothing
        @test n[:text] === nothing
        @test n[:graphics] === nothing
        @test haskey(n,:tools)
        @test n[:tools] === nothing || isempty(n[:tools])
        @test haskey(n,:labels)
        @test n[:labels] === nothing || isempty(n[:labels])
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
        n = parse_node(to_node(s))
        printnode(n)
        @test n[:tag] == :hlinscription
        @test isnothing(n[:xml]) ||  n[:xml] isa EzXML.Node
    end
end

