using PNML, EzXML, ..TestUtils, JET
using PNML: Maybe, tag, xmlnode, labels, firstpage, pid

header("DECLARATIONS")
@testset "Declaration()" begin
    @show d = PNML.Declaration()
    @test length(PNML.declarations(d)) == 0
    @show Core.fieldtype(PNML.Declaration, 1)
    @test_call PNML.Declaration()
end # declarations

@testset "empty declarations" begin
    # The attribute should be ignored.
    n = parse_node(xml"""
        <declaration key="test">
          <structure>
           <declarations>
           </declarations>
          </structure>
        </declaration>
        """; reg = PNML.IDRegistry())

    @show typeof(n), fieldnames(typeof(n))
    printnode(n)

    @test typeof(n) <: PNML.Declaration
    @test xmlnode(n) isa Maybe{EzXML.Node}
    @test typeof(PNML.declarations(n)) <: Vector{Any} #TODO {PNML.AbstractDeclaration}
    @test length(PNML.declarations(n)) == 0

    @test typeof(n.com) <: PNML.ObjectCommon
    @test PNML.graphics(n) === nothing
    @test PNML.tools(n) === nothing
    @test PNML.labels(n) === nothing
    @test isempty(n.com)

    @test_call PNML.declarations(n)
    @test_call PNML.graphics(n)
    @test_call PNML.tools(n)
    @test_call PNML.labels(n)
end

@testset "declaration tree" begin
        node = xml"""
        <declaration>
            <structure>
                <declarations>
                    <namedsort id="LegalResident" name="LegalResident">
                        <cyclicenumeration>
                            <feconstant id="LegalResident0" name="0"/>
                            <feconstant id="LegalResident1" name="1"/>
                        </cyclicenumeration>
                    </namedsort>
                    <namedsort id="MICSystem" name="MICSystem">
                        <cyclicenumeration>
                            <feconstant id="MICSystem0" name="0"/>
                            <feconstant id="MICSystem1" name="1"/>
                        </cyclicenumeration>
                    </namedsort>
                    <namedsort id="CINFORMI" name="CINFORMI">
                        <cyclicenumeration>
                            <feconstant id="CINFORMI0" name="0"/>
                            <feconstant id="CINFORMI1" name="1"/>
                        </cyclicenumeration>
                    </namedsort>
            </declarations>
        </structure>
    </declaration>
    """
    reg = PNML.IDRegistry()
    n = parse_node(node; reg)
    printnode(n)

    @test typeof(n) <: PNML.Declaration
    @test xmlnode(n) isa Maybe{EzXML.Node}
    @test length(PNML.declarations(n)) == 3
    @test_call PNML.declarations(n)

    for d in PNML.declarations(n)
        @show typeof(d)
        @test typeof(d) <: PNML.AbstractDeclaration
        @test typeof(d) <: PNML.SortDeclaration
        @test typeof(d) <: PNML.NamedSort

        #@show d
        #@show fieldtypes(typeof(d))
        #@show fieldnames(typeof(d))
        #@show fieldtypes(typeof(d.def))
        #@show fieldnames(typeof(d.def))

        @test PNML.isregistered(reg, pid(d))
        @test_call PNML.isregistered(reg, pid(d))
        @test Symbol(PNML.name(d)) === pid(d) # name and id are the same.
        @test d.def isa PNML.AnyElement #TODO implement definitions?
        @test tag(d.def) === :cyclicenumeration
        @test haskey(d.def.dict, :feconstant)

        for x in d.def.dict[:feconstant]
            @test x isa PnmlDict
            @test PNML.isregistered(reg, pid(x))
            @test x[:name] isa String
            @test endswith(string(pid(x)), x[:name])
        end
        #println()
    end
end
