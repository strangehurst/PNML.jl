using PNML, EzXML, ..TestUtils, JET
using PNML:
    Maybe, tag, xmlnode, labels, pid, parse_sort, parse_declaration
    registry

const pntd = PnmlCoreNet()

@testset "Declaration()" begin
    decl = PNML.Declaration()
    @test length(PNML.declarations(decl)) == 0
    @test_call PNML.Declaration()
end

@testset "parse_sort" begin
    @show parse_sort(xml"<bool/>", PnmlCoreNet(), registry())
    @show parse_sort(xml"<finiteenumeration/>", PnmlCoreNet(), registry())
    @show parse_sort(xml"<finiteintrange/>", PnmlCoreNet(), registry())
    @show parse_sort(xml"<cyclicenumeration/>", PnmlCoreNet(), registry())
    @show parse_sort(xml"<dot/>", PnmlCoreNet(), registry())
    @show parse_sort(xml"<mulitsetsort/>", PnmlCoreNet(), registry())
    @show parse_sort(xml"<productsort/>", PnmlCoreNet(), registry())
    @show parse_sort(xml"<usersort/>", PnmlCoreNet(), registry())
    @show parse_sort(xml"<partition/>", PnmlCoreNet(), registry())
end

@testset "empty declarations" begin
    # The attribute should be ignored.
    decl = parse_declaration(xml"""
        <declaration key="test empty">
          <structure>
           <declarations>
           </declarations>
          </structure>
        </declaration>
        """, pntd, registry())

    @test typeof(decl) <: PNML.Declaration
    @test xmlnode(decl) isa Maybe{EzXML.Node}
    @test typeof(PNML.declarations(decl)) <: Vector{Any} #TODO {AbstractDeclaration}
    @test length(PNML.declarations(decl)) == 0

    @test typeof(PNML.common(decl)) <: PNML.ObjectCommon
    @test PNML.graphics(decl) === nothing
    @test PNML.tools(decl) === nothing
    @test PNML.labels(decl) === nothing
    @test isempty(PNML.common(decl))

    @test_call PNML.declarations(decl)
    @test_call PNML.graphics(decl)
    @test_call PNML.tools(decl)
    @test_call PNML.labels(decl)
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
    reg = PNML.registry()
    decl = parse_declaration(node, pntd, reg)

    @show typeof(decl)
    @test typeof(decl) <: PNML.Declaration
    @test xmlnode(decl) isa Maybe{EzXML.Node}
    @test length(PNML.declarations(decl)) == 3
    @test_call PNML.declarations(decl)

    for d in PNML.declarations(decl)
        @show d
        @test typeof(d) <: PNML.AbstractDeclaration
        @test typeof(d) <: PNML.SortDeclaration
        @test typeof(d) <: PNML.NamedSort

        @test PNML.isregistered(reg, pid(d))
        @test_call PNML.isregistered(reg, pid(d))
        @test Symbol(PNML.name(d)) === pid(d) # name and id are the same.
        @test d.def isa PNML.AnyElement #TODO implement definitions?
        @test tag(d.def) === :cyclicenumeration
        @test haskey(d.def.elements, :feconstant)

        for x in d.def.elements[:feconstant]
            @show x
            @test x isa NamedTuple
            @test PNML.isregistered(reg, pid(x))
            @test x[:name] isa String
            @test endswith(string(pid(x)), x[:name])
        end
    end
end
