using PNML, EzXML, ..TestUtils, JET
using PNML: Maybe, tag, pid, xmlnode

#!header("PARSE HL LABELS")

#!header("HL Marking")
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
    n = parse_node(xmlroot(str), HLCore(); reg = PNML.IDRegistry())
    #!@show typeof(n), fieldnames(typeof(n))
    #!printnode(n)

    @test typeof(n) <: PNML.AbstractLabel
    @test typeof(n) <: PNML.HLMarking
    #@test xmlnode(n) isa Maybe{EzXML.Node}
    @test n.text == "<All,All>"
    @test n.term !== nothing
    @test n.term isa PNML.AbstractTerm

    #!@show typeof(n.term), fieldnames(typeof(n.term))
    #!@show n.term
    @test tag(n.term) === :tuple
    @test n.term.dict[:subterm][1][:all] !== nothing
    @test n.term.dict[:subterm][1][:all][:usersort][:declaration] == "N1"
    @test n.term.dict[:subterm][2][:all][:usersort][:declaration] == "N2"
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
    n = parse_node(n1, HLCore(); reg = PNML.IDRegistry())
    #!printnode(n)
    @test typeof(n) <: PNML.HLInscription
    #@test xmlnode(n) isa Maybe{EzXML.Node}
    @test tag(n.term) === :tuple
    @test n.term.dict[:subterm][1][:variable][:refvariable] == "x"
    @test n.term.dict[:subterm][2][:variable][:refvariable] == "v"
    @test n.text == "<x,v>"
end

#!header("STRUCTURE")
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

    n = parse_node(node, HLCore(); reg = PNML.IDRegistry())
    #!printnode(n)
    @test n isa PNML.Structure
    @test xmlnode(n) isa Maybe{EzXML.Node}
    @test tag(n) === :structure
    @test n.dict isa PnmlDict
    @test tag(n) === :structure
    @test n.dict[:tuple][:subterm][1][:all][:usersort][:declaration] == "N1"
    @test n.dict[:tuple][:subterm][2][:all][:usersort][:declaration] == "N2"
end

#!header("SORT TYPE")
@testset "type" begin
    n1 = xml"""
 <type>
     <text>N2</text>
     <structure> <usersort declaration="N2"/> </structure>
 </type>
    """
    @testset for node in [n1]
        n = parse_node(node, HLCore(); reg = PNML.IDRegistry())
        #!printnode(n)
        @test typeof(n) <: PNML.AnyElement
        @test tag(n) === :type
        @test n.dict[:text][:content] == "N2"
        @test n.dict[:structure][:usersort][:declaration] == "N2"
    end
end

#!header("CONDITION")
@testset "condition" begin
    n1 = xml"""
 <condition>
     <text>(x==1 and y==1 and d==1)</text>
     <structure> <or> #TODO </or> </structure>
 </condition>
    """
    @testset for node in [n1]
        n = parse_node(node, PnmlCore(); reg = PNML.IDRegistry())
        #!printnode(n)
        @test typeof(n) <: PNML.Condition
        @test n.text !== nothing
        @test n.term !== nothing
        @test tag(n.term) === :or
        @test n.com.graphics === nothing
        @test n.com.tools === nothing || isempty(n.com.tools)
        @test n.com.labels === nothing || isempty(n.com.labels)
    end
end
