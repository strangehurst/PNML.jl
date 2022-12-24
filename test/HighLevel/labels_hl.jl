using PNML, EzXML, ..TestUtils, JET
using PNML: Maybe, tag, pid, xmlnode, value

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
    n = parse_node(xmlroot(str), HLCoreNet(); reg = PNML.IDRegistry())

    @test typeof(n) <: PNML.AbstractLabel
    @test typeof(n) <: PNML.HLMarking
    #@test xmlnode(n) isa Maybe{EzXML.Node}
    @test n.text == "<All,All>"
    @test value(n) !== nothing
    @test value(n) isa PNML.AbstractTerm

    @test tag(value(n)) === :tuple
    @test value(n).dict[:subterm][1][:all] !== nothing
    @test value(n).dict[:subterm][1][:all][:usersort][:declaration] == "N1"
    @test value(n).dict[:subterm][2][:all][:usersort][:declaration] == "N2"
end

@testset "hlinscription" begin
    n1 = xml"""
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
    n = parse_node(n1, HLCoreNet(); reg = PNML.IDRegistry())
    @test typeof(n) <: PNML.HLInscription
    #@test xmlnode(n) isa Maybe{EzXML.Node}
    @test tag(value(n)) === :tuple
    @test value(n).dict[:subterm][1][:variable][:refvariable] == "x"
    @test value(n).dict[:subterm][2][:variable][:refvariable] == "v"
    @test n.text == "<x,v>"
end

@testset "structure" begin
    node = xml"""
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

    n = parse_node(node, HLCoreNet(); reg = PNML.IDRegistry())
    @test n isa PNML.Structure
    @test xmlnode(n) isa Maybe{EzXML.Node}
    @test tag(n) === :structure
    @test n.dict isa PnmlDict
    @test tag(n) === :structure
    @test n.dict[:tuple][:subterm][1][:all][:usersort][:declaration] == "N1"
    @test n.dict[:tuple][:subterm][2][:all][:usersort][:declaration] == "N2"
end

@testset "type" begin
    n1 = xml"""
 <type>
     <text>N2</text>
     <structure> <usersort declaration="N2"/> </structure>
 </type>
    """
    @testset for node in [n1]
        n = parse_node(node, HLCoreNet(); reg = PNML.IDRegistry())
        @test typeof(n) <: PNML.AnyElement
        @test tag(n) === :type
        @test n.dict[:text][:content] == "N2"
        @test n.dict[:structure][:usersort][:declaration] == "N2"
    end
end

@testset "condition" begin
    n1 = xml"""
 <condition>
     <text>(x==1 and y==1 and d==1)</text>
     <structure> <or> #TODO </or> </structure>
 </condition>
    """
    @testset for node in [n1]
        n = parse_node(node, PnmlCoreNet(); reg = PNML.IDRegistry())
        @test typeof(n) <: PNML.Condition
        @test n.text !== nothing
        @test value(n) !== nothing
        @test tag(value(n)) === :or
        @test n.com.graphics === nothing
        @test n.com.tools === nothing || isempty(n.com.tools)
        @test n.com.labels === nothing || isempty(n.com.labels)
    end
end
