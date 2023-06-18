using PNML, EzXML, ..TestUtils, JET
using PNML:
    Maybe, tag, xmlnode, labels, pid, parse_sort, parse_declaration,
    registry, AnyElement, AnyXmlNode, name, value, isregistered

const pntd::PnmlType = PnmlCoreNet()

@testset "Declaration()" begin
    decl = PNML.Declaration()
    @test length(PNML.declarations(decl)) == 0
    @test_call PNML.Declaration()
end

@testset "parse_sort" begin
    @test parse_sort(xml"<bool/>", PnmlCoreNet(), registry()) isa AnyElement
    @test parse_sort(xml"<finiteenumeration/>", PnmlCoreNet(), registry()) isa AnyElement
    @test parse_sort(xml"<finiteintrange/>", PnmlCoreNet(), registry()) isa AnyElement
    @test parse_sort(xml"<cyclicenumeration/>", PnmlCoreNet(), registry()) isa AnyElement
    @test parse_sort(xml"<dot/>", PnmlCoreNet(), registry()) isa AnyElement
    @test parse_sort(xml"<mulitsetsort/>", PnmlCoreNet(), registry()) isa AnyElement
    @test parse_sort(xml"<productsort/>", PnmlCoreNet(), registry()) isa AnyElement
    @test parse_sort(xml"<usersort/>", PnmlCoreNet(), registry()) isa AnyElement
    @test parse_sort(xml"<partition/>", PnmlCoreNet(), registry()) isa AnyElement
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
    @test PNML.tools(decl) !== nothing
    @test PNML.labels(decl) !== nothing
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

    @test typeof(decl) <: PNML.Declaration
    @test xmlnode(decl) isa Maybe{EzXML.Node}
    @test length(PNML.declarations(decl)) == 3
    @test_call PNML.declarations(decl)

    # Examine each declaration in the vector: 3 named sorts
    #println("dump(decl)"); dump(decl)
    for d in PNML.declarations(decl)
        #println("\n  declaration $(pid(d))"); dump(d)
        @test typeof(d) <: PNML.AbstractDeclaration
        @test typeof(d) <: PNML.SortDeclaration
        @test typeof(d) <: PNML.NamedSort
        # named sort -> cyclic enumeration -> fe constant
        @test isregistered(reg, pid(d))
        @test_call isregistered(reg, pid(d))
        sortname = PNML.name(d)
        @test Symbol(PNML.name(d)) === pid(d) # name and id are the same.
        @test d.def isa PNML.AnyElement
        @test tag(d.def) === :cyclicenumeration
        @test d.def.elements isa Vector{PNML.AnyXmlNode}

        @test tag(d.def.elements[1]) === :feconstant
        let x = value(d.def.elements[1])
            @test x isa Vector{AnyXmlNode}

            @test tag(x[1]) === :id
            idstring = value(x[1])
            @test idstring isa AbstractString
            #@test idstring == "LegalResident0"
            @test startswith(idstring, sortname)
            @test_call isregistered(reg, Symbol(idstring)) # unclaimed id
            @test !isregistered(reg, Symbol(idstring)) # unclaimed id

            @test tag(x[2]) === :name
            namestring = value(x[2])
            @test namestring isa AbstractString
            @test namestring == "0"
            @test endswith(idstring, namestring)
        end
    end
end
