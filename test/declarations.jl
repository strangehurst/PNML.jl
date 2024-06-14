using PNML, EzXML, ..TestUtils, JET
using InteractiveUtils
using Printf

function _subtypes(type::Type)
    out = Any[]
    _subtypes!(out, type)
end

function _subtypes!(out, type::Type)
    if !isabstracttype(type)
        push!(out, type)
    else
        foreach(Base.Fix1(_subtypes!, out), subtypes(type))
    end
    return out
end

sorts() = _subtypes(AbstractSort)

@testset "parse_sort $pntd" for pntd in core_nettypes()
    sort = @inferred AbstractSort parse_sort(xml"<usersort declaration=\"X\"/>", pntd, registry(); ids=(:NN,))
    @test sort isa UserSort
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    sort = @inferred AbstractSort parse_sort(xml"<dot/>", pntd, registry(); ids=(:NN,))
    @test sort isa DotSort
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    sort = @inferred AbstractSort parse_sort(xml"<bool/>", pntd, registry(); ids=(:NN,))
    @test sort isa BoolSort
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    sort = @inferred AbstractSort parse_sort(xml"<integer/>", pntd, registry(); ids=(:NN,))
    @test sort isa IntegerSort
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    sort = @inferred AbstractSort parse_sort(xml"<natural/>", pntd, registry(); ids=(:NN,))
    @test sort isa PNML.NaturalSort
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    sort = @inferred AbstractSort parse_sort(xml"<positive/>", pntd, registry(); ids=(:NN,))
    @test sort isa PNML.PositiveSort
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    sort = @inferred AbstractSort parse_sort(xml"""<cyclicenumeration>
                                <feconstant id="FE0" name="0"/>
                                <feconstant id="FE1" name="1"/>
                            </cyclicenumeration>""", PnmlCoreNet(), registry(); ids=(:NN,))
    @test sort isa PNML.CyclicEnumerationSort
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    sort = @inferred AbstractSort parse_sort(xml"""<finiteenumeration>
                                <feconstant id="FE0" name="0"/>
                                <feconstant id="FE1" name="1"/>
                           </finiteenumeration>""", pntd, registry(); ids=(:NN,))
    @test sort isa PNML.FiniteEnumerationSort
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    sort = @inferred AbstractSort parse_sort(xml"<finiteintrange start=\"2\" end=\"3\"/>", pntd, registry(); ids=(:NN,))
    @test sort isa PNML.FiniteIntRangeSort
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    @test_throws "<productsort> contains no sorts" parse_sort(xml"""<productsort/>""", pntd, registry(); ids=(:NN,))

    sort = @inferred AbstractSort parse_sort(xml"""<productsort>
                                <usersort declaration="a_user_sort"/>
                           </productsort>""", pntd, registry(); ids=(:NN,))
                           sprint(show, sort)
    @test sort isa PNML.ProductSort
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    sort = @inferred AbstractSort parse_sort(xml"""<productsort>
                           <usersort declaration="speed"/>
                           <usersort declaration="distance"/>
                         </productsort>""", pntd, registry(); ids=(:NN,))
    @test sort isa PNML.ProductSort
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    sort = @inferred AbstractSort parse_sort(xml"""<productsort>
                               <usersort declaration="id1"/>
                               <natural/>
                            </productsort>""", pntd, registry(); ids=(:NN,))
    @test sort isa PNML.ProductSort
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    sort = @inferred AbstractSort parse_sort(xml"""<multisetsort>
                                <usersort declaration="duck"/>
                            </multisetsort>""", pntd, registry(); ids=(:NN,))
    @test sort isa PNML.MultisetSort
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    sort = @inferred AbstractSort parse_sort(xml"""<multisetsort>
                                <natural/>
                            </multisetsort>""", pntd, registry(); ids=(:NN,))
    @test sort isa Maybe{PNML.MultisetSort}
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)
end

@testset "empty declarations $pntd" for pntd in core_nettypes()
    empty!(PNML.TOPDECLDICTIONARY)
    PNML.TOPDECLDICTIONARY[:NULLNET] = PNML.DeclDict()
    # The attribute should be ignored.
    decl = @inferred parse_declaration(xml"""<declaration key="test empty">
            <structure><declarations></declarations></structure>
        </declaration>""", pntd, registry(); ids=(:NULLNET,))

    @test typeof(decl) <: PNML.Declaration
    @test length(decl) == 0 # nothing in <declarations>
    @test isempty(decl)
    @test isempty(decldict(:NULLNET))
    @test PNML.graphics(decl) === nothing
    @test PNML.tools(decl) === nothing

    @test_opt PNML.declarations(decl)
    @test_opt PNML.graphics(decl)
    @test_opt PNML.tools(decl)

    @test_call PNML.declarations(decl)
    @test_call PNML.graphics(decl)
    @test_call PNML.tools(decl)
end

@testset "namedsort declaration $pntd" for pntd in core_nettypes()
    PNML.TOPDECLDICTIONARY[:NULLNET] = PNML.DeclDict()
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
    PNML.TOPDECLDICTIONARY[:NULLNET] = PNML.DeclDict()
    reg = PNML.registry()
    decl = parse_declaration(node, pntd, reg; ids=(:NULLNET,))
    @test typeof(decl) <: PNML.Declaration
    PNML.declarations(decl)

    # Examine each declaration in the vector: 3 named sorts
    for nsort in PNML.declarations(decl)
        # named sort -> cyclic enumeration -> fe constant
        #!@test typeof(nsort) <: PNML.NamedSort # is a declaration

        @test isregistered(reg, pid(nsort))
        #!@test Symbol(PNML.name(nsort)) === pid(nsort) # NOT TRUE! name and id are the same.
        #!@test PNML.sortof(nsort) isa PNML.CyclicEnumerationSort
        #@test PNML.elements(PNML.sortof(nsort)) isa Vector{PNML.FEConstant}

        sortname = PNML.name(nsort)
        #!cesort   = PNML.sortof(nsort)
        #!feconsts = PNML.elements(cesort) # should be iteratable ordered collection
        #@test feconsts isa Vector{PNML.FEConstant}
        #!@test length(feconsts) == 2
        # for fec in feconsts
        #     @test fec isa PNML.FEConstant
        #     @test fec.id isa Symbol
        #     @test fec.name isa AbstractString
        #     @test isregistered(reg, fec.id)

        #     @test endswith(string(fec.id), fec.name)
        # end
    end
end


@testset "partition declaration $pntd" for pntd in core_nettypes()
    PNML.TOPDECLDICTIONARY[:NULLNET] = PNML.DeclDict()
    node = xml"""
    <declaration>
        <structure>
            <declarations>
                <partition id="P1" name="P1">
                    <usersort declaration="pluck"/>
                    <partitionelement id="bs1" name="bs1">
                        <useroperator declaration="b1"/>
                        <useroperator declaration="b2"/>
                        <useroperator declaration="b3"/>
                    </partitionelement>
                </partition>
                <partition id="P2" name="P2">
                    <usersort declaration="pluck2"/>
                    <partitionelement id="bs2" name="bs2">
                        <useroperator declaration="b4"/>
                    </partitionelement>
                </partition>
                <partition id="P3" name="P3">
                    <usersort declaration="pluck2"/>
                    <partitionelement id="bs3" name="bs3">
                        <useroperator declaration="b5"/>
                    </partitionelement>
                    <partitionelement id="bs4" name="bs4">
                        <useroperator declaration="b6"/>
                    </partitionelement>
                </partition>
            </declarations>
        </structure>
    </declaration>
    """
    reg = PNML.registry()
    decl = parse_declaration(node, pntd, reg; ids=(:NULLNET,))
    @test typeof(decl) <: Declaration

    # Examine each declaration in the vector: 3 partition sorts
    for psort in PNML.declarations(decl)
        # named partition -> partition element -> fe constant
        @test typeof(psort) <: PartitionSort # is a declaration

        @test PNML.isregistered(reg, pid(psort))
        @test Symbol(PNML.name(psort)) === pid(psort) # name and id are the same.

        partname = PNML.name(psort)
        partsort = PNML.sortof(psort)::UserSort
        part_elements = PNML.elements(psort)::Vector{PartitionElement}

        for element in part_elements
            @test PNML.isregistered(reg, pid(element))
        end
    end
end

const nonsimple_sorts = (MultisetSort, UserSort,
    CyclicEnumerationSort, FiniteEnumerationSort, FiniteIntRangeSort)

@testset "equal sorts" begin
    println("============================")
    println("  equal sorts: $(sorts())")
    println("============================")
    #TODO PartitionSort is confused - a SortDeclaration - there should be more and a mechanism
    for s in [x for x in sorts() if x ∉ nonsimple_sorts]
        println(s)
        a = s()
        b = s()
        @test PNML.equals(a, a)
    end

    for sorta in [x for x in sorts() if x ∉ nonsimple_sorts]
        for sortb in [x for x in sorts() if x ∉ nonsimple_sorts]
            a = sorta()
            b = sortb()
            #println(repr(a), " == ", repr(b), " --> ", PNML.equals(a, b), ", ", (a == b))
            sorta != sortb && @test a != b && !PNML.equals(a, b)
            sorta == sortb && @test PNML.equals(a, b)::Bool && (a == b)
        end
    end

    #TODO Add tests for enumerated sorts, et al., with content.
    # MultisetSort
    for sorta in [x for x in sorts() if x ∉ nonsimple_sorts]
        for sortb in [x for x in sorts() if x ∉ nonsimple_sorts]
            a = PNML.MultisetSort(sorta())
            b = PNML.MultisetSort(sortb())
            sorta != sortb && @test a != b && !PNML.equals(a, b)
            sorta == sortb && @test PNML.equals(a, b)::Bool && (a == b)
        end
    end
    println("============================")
end
