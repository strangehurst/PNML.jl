using PNML, EzXML, ..TestUtils, JET
using PNML:
    Maybe, tag, labels, pid, parse_sort, parse_declaration,
    registry, AnyElement, AnyXmlNode, name, value, isregistered

@testset "Declaration() $pntd" for pntd in all_nettypes()
    decl = PNML.Declaration()
    @test length(PNML.declarations(decl)) == 0
    @test_call PNML.Declaration()
end

using InteractiveUtils, Printf
function _subtypes(type::Type)
    out = Any[]
    _subtypes!(out, type)
end
function _subtypes!(out, type::Type)
    if !isabstracttype(type)
        push!(out, type)
    else
        foreach(T->_subtypes!(out, T), subtypes(type))
    end
    out
end

@testset "AbstractDeclarations $pntd" for pntd in all_nettypes()
    Base.redirect_stdio(stdout=testshow, stderr=testshow) do
        @show _subtypes(PNML.AbstractDeclaration)
        for decl in _subtypes(PNML.AbstractDeclaration)
            @show decl decl()
            #@printf "%-25s %s\n" decl "x"
        end
   end
end

@testset "parse_sort $pntd" for pntd in all_nettypes()
    @test parse_sort(xml"<usersort declaration=\"X\"/>", pntd, registry()) isa PNML.UserSort
    @test parse_sort(xml"<dot/>", pntd, registry()) isa PNML.DotSort
    @test parse_sort(xml"<bool/>", pntd, registry()) isa PNML.BoolSort
    @test parse_sort(xml"<integer/>", pntd, registry()) isa PNML.IntegerSort
    @test parse_sort(xml"<natural/>", pntd, registry()) isa PNML.NaturalSort
    @test parse_sort(xml"<positive/>", pntd, registry()) isa PNML.PositiveSort

    @test parse_sort(xml"""<cyclicenumeration>
                                <feconstant id="FE0" name="0"/>
                                <feconstant id="FE1" name="1"/>
                           </cyclicenumeration>""", PnmlCoreNet(), registry()) isa PNML.CyclicEnumerationSort
    @test parse_sort(xml"""<finiteenumeration>
                                <feconstant id="FE0" name="0"/>
                                <feconstant id="FE1" name="1"/>
                           </finiteenumeration>""", pntd, registry()) isa PNML.FiniteEnumerationSort

    @test parse_sort(xml"<finiteintrange start=\"2\" stop=\"3\"/>", pntd, registry()) isa PNML.FiniteIntRangeSort

    @test parse_sort(xml"""<productsort>
                                <usersort declaration="speed"/>
                                <usersort declaration="distance"/>
                           </productsort>""", pntd, registry()) isa PNML.ProductSort

    @test parse_sort(xml"""<partition id="P1" name="P1">
                                <usersort declaration="pluck"/>
                                <partitionelement id="bs1" name="bs1">
                                    <useroperator declaration="b1"/>
                                    <useroperator declaration="b2"/>
                                    <useroperator declaration="b3"/>
                               </partitionelement>
                           </partition>""", pntd, registry()) isa PNML.PartitionSort

    @test parse_sort(xml"""<multisetsort>
                                <usersort declaration="duck"/>
                           </multisetsort>""", pntd, registry()) isa PNML.MultisetSort
end

@testset "empty declarations $pntd" for pntd in all_nettypes()
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
    @test typeof(PNML.declarations(decl)) <: Vector{Any} #TODO {AbstractDeclaration}
    @test length(PNML.declarations(decl)) == 0 # notining in <declarations>

    @test PNML.has_graphics(decl) == false
    @test PNML.has_tools(decl)    == true
    @test PNML.has_labels(decl)   == false

    @test PNML.graphics(decl) === nothing
    @test isempty(PNML.tools(decl))
    #@test PNML.labels(decl) !== nothing


    @test_call PNML.declarations(decl)
    @test_call PNML.graphics(decl)
    @test_call PNML.tools(decl)
    #@test_call PNML.labels(decl)
end

@testset "declaration tree $pntd" for pntd in all_nettypes()
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
    Base.redirect_stdio(stdout=testshow, stderr=testshow) do
        @show decl
    end
    @test typeof(decl) <: PNML.Declaration
    @test length(PNML.declarations(decl)) == 3
    @test_call PNML.declarations(decl)

    # Examine each declaration in the vector: 3 named sorts
    #println("dump(decl)"); dump(decl)
    for nsort in PNML.declarations(decl) # named sort -> cyclic enumeration -> fe constant
        @test typeof(nsort) <: PNML.AbstractDeclaration
        @test typeof(nsort) <: PNML.SortDeclaration
        @test typeof(nsort) <: PNML.NamedSort

        @test isregistered(reg, pid(nsort))
        @test_call isregistered(reg, pid(nsort))
        @test Symbol(PNML.name(nsort)) === pid(nsort) # name and id are the same.
        #println("declaration"); dump(nsort) #! debug
        @test PNML.sort(nsort) isa PNML.CyclicEnumerationSort
        @test PNML.elements(PNML.sort(nsort)) isa Vector{PNML.FEConstant}

        sortname = PNML.name(nsort)
        cesort   = PNML.sort(nsort)
        feconsts = PNML.elements(cesort) # should be iteratable ordered collection
        @test feconsts isa Vector{PNML.FEConstant}
        @test length(feconsts) == 2
        for fec in feconsts
            @test fec isa PNML.FEConstant

            @test fec.id isa Symbol
            @test fec.name isa AbstractString
            #@test idstring == "LegalResident0"
            @test_call isregistered(reg, fec.id)
            @test !isregistered(reg, fec.id) # unregistered id

            @test endswith(string(fec.id), fec.name)
        end
    end
end
