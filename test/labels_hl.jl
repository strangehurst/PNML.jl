using PNML, EzXML, ..TestUtils, JET, PrettyPrinting
using PNML: Maybe, tag, pid, xmlnode, value, text, elements

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
    mark = PNML.parse_hlinitialMarking(xmlroot(str), HLCoreNet(), registry())

    @test typeof(mark) <: PNML.AbstractLabel
    @test typeof(mark) <: PNML.HLMarking
    @test text(mark) == "<All,All>"
    @test value(mark) !== nothing
    @test value(mark) isa PNML.AbstractTerm
    @test tag(value(mark)) === :tuple

    @show value(mark).elements.subterm[1].all.usersort.declaration
    @show value(mark).elements.subterm[1].all.usersort.content
    @show value(mark).elements.subterm[2].all.usersort.declaration
    @show value(mark).elements.subterm[2].all.usersort.content

    @test value(mark).elements.subterm[1].all.usersort.declaration == "N1"
    @test value(mark).elements.subterm[1].all.usersort.content == ""
    @test value(mark).elements.subterm[2].all.usersort.declaration == "N2"
    @test value(mark).elements.subterm[2].all.usersort.content == ""
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
    insc = PNML.parse_hlinscription(n1, HLCoreNet(), registry())
    @test typeof(insc) <: PNML.HLInscription
    @test text(insc) isa Union{Nothing,AbstractString}
    @test value(insc) isa PNML.Term
    @show insc value(insc)
    @test tag(value(insc)) === :tuple
    @test value(insc).elements.subterm[1].variable.refvariable == "x"
    @test value(insc).elements.subterm[2].variable.refvariable == "v"
    @test text(insc) == "<x,v>"
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

    stru = PNML.parse_structure(node, HLCoreNet(), registry())
    @test stru isa PNML.Structure
    @test xmlnode(stru) isa Maybe{EzXML.Node}
    print("Structure = "); pprint(stru)
    @test tag(stru) === :structure
    @test elements(stru) isa NamedTuple
    @test tag(stru) === :structure
    @show elements(stru).tuple
    @test elements(stru).tuple.subterm[1].all.usersort.declaration == "N1"
    @test elements(stru).tuple.subterm[2].all.usersort.declaration == "N2"
end

@testset "type" begin
    n1 = xml"""
 <type>
     <text>N2</text>
     <structure> <usersort declaration="N2"/> </structure>
 </type>
    """
    @testset for node in [n1]
        typ = PNML.parse_type(node, HLCoreNet(), registry())
        print("SortType = "); pprintln(typ)
        @test typ isa PNML.SortType
        @test text(typ) == "N2"
        @test value(typ) isa PNML.Term
        @test (tag ∘ value)(typ) === :usersort
        @test (elements ∘ value)(typ) isa NamedTuple
        @test (elements ∘ value)(typ).declaration == "N2"
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
        con = PNML.parse_condition(node, PnmlCoreNet(), registry())
        @show con
        @test typeof(con) <: PNML.Condition
        @test text(con) !== nothing
        @test value(con) !== nothing
        @test tag(value(con)) === :or
        @test (PNML.graphics ∘ PNML.common)(con) === nothing
        @test (PNML.tools ∘ PNML.common)(con) === nothing || !has_tools(con)
        @test (PNML.labels ∘ PNML.common)(con) ===  nothing || !has_labels(con)
    end
end
