using PNML, EzXML, ..TestUtils, JET
using  InteractiveUtils
using PNML: Maybe, tag, labels, pid, AnyElement, name, value,
    parse_sort, parse_declaration,
    registry, isregistered,
    DictType, AbstractDeclaration,
    getfirst, firstchild, allchildren,
    ishighlevel, PnmlTypeDefs,
    Condition, Term,
    default_bool_term, default_zero_term, default_one_term,
    default_condition, default_inscription, default_marking, default_sort, default_sorttype,
    page_type, place_type, transition_type, arc_type, marking_type, inscription_type, condition_type,
    condition_value_type, rate_value_type, term_value_type,
    AbstractSort, BoolSort, DotSort, IntegerSort, NaturalSort, PositiveSort,
    MultisetSort, ProductSort, RealSort, UserSort, SortType

@testset "Declaration() $pntd" for pntd in all_nettypes()
    decl = PNML.Declaration()
    @test length(PNML.declarations(decl)) == 0
    @test_opt PNML.Declaration()
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

@testset "parse_sort $pntd" for pntd in all_nettypes()
    sort = parse_sort(xml"<usersort declaration=\"X\"/>", pntd, registry())
    @test sort isa PNML.UserSort
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    sort = parse_sort(xml"<dot/>", pntd, registry())
    @test sort isa PNML.DotSort
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    sort =  parse_sort(xml"<bool/>", pntd, registry())
    @test sort isa PNML.BoolSort
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    sort = parse_sort(xml"<integer/>", pntd, registry())
    @test sort isa PNML.IntegerSort
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    sort = parse_sort(xml"<natural/>", pntd, registry())
    @test sort isa PNML.NaturalSort
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    sort = parse_sort(xml"<positive/>", pntd, registry())
    @test sort isa PNML.PositiveSort
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    sort = parse_sort(xml"""<cyclicenumeration>
                                <feconstant id="FE0" name="0"/>
                                <feconstant id="FE1" name="1"/>
                            </cyclicenumeration>""", PnmlCoreNet(), registry())
    @test sort isa PNML.CyclicEnumerationSort
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    sort = parse_sort(xml"""<finiteenumeration>
                                <feconstant id="FE0" name="0"/>
                                <feconstant id="FE1" name="1"/>
                           </finiteenumeration>""", pntd, registry())
    @test sort isa PNML.FiniteEnumerationSort
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    sort = parse_sort(xml"<finiteintrange start=\"2\" end=\"3\"/>", pntd, registry())
    @test sort isa PNML.FiniteIntRangeSort
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    sort = parse_sort(xml"""<productsort>
                          </productsort>""", pntd, registry())
    @test sort isa PNML.ProductSort
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    sort = parse_sort(xml"""<productsort>
                                <usersort declaration="a_user_sort"/>
                           </productsort>""", pntd, registry())
                           sprint(show, sort)
    @test sort isa PNML.ProductSort
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    sort = parse_sort(xml"""<productsort>
                           <usersort declaration="speed"/>
                           <usersort declaration="distance"/>
                         </productsort>""", pntd, registry())
    @test sort isa PNML.ProductSort
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    sort = parse_sort(xml"""<productsort>
                               <usersort declaration="id1"/>
                               <natural/>
                            </productsort>""", pntd, registry())
    @test sort isa PNML.ProductSort
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    sort = parse_sort(xml"""<multisetsort>
                                <usersort declaration="duck"/>
                            </multisetsort>""", pntd, registry())
    @test sort isa PNML.MultisetSort
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    sort = parse_sort(xml"""<multisetsort>
                                <natural/>
                            </multisetsort>""", pntd, registry())
    @test sort isa Maybe{PNML.MultisetSort}
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)
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
    @test typeof(PNML.declarations(decl)) <: Vector{AbstractDeclaration}
    @test length(PNML.declarations(decl)) == 0 # notining in <declarations>

    @test PNML.graphics(decl) === nothing
    @test PNML.tools(decl) === nothing


    @test_opt PNML.declarations(decl)
    @test_opt PNML.graphics(decl)
    @test_opt PNML.tools(decl)

    @test_call PNML.declarations(decl)
    @test_call PNML.graphics(decl)
    @test_call PNML.tools(decl)
end

@testset "namedsort declaration $pntd" for pntd in all_nettypes()
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
    @test length(PNML.declarations(decl)) == 3

    # Examine each declaration in the vector: 3 named sorts
    for nsort in PNML.declarations(decl)
        # named sort -> cyclic enumeration -> fe constant
        @test typeof(nsort) <: PNML.NamedSort # is a declaration

        @test isregistered(reg, pid(nsort))
        @test Symbol(PNML.name(nsort)) === pid(nsort) # name and id are the same.
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
            @test !isregistered(reg, fec.id) # unregistered id

            @test endswith(string(fec.id), fec.name)
        end
    end
end


@testset "partition declaration $pntd" for pntd in all_nettypes()
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
    decl = parse_declaration(node, pntd, reg)
    @test typeof(decl) <: PNML.Declaration
    @test length(PNML.declarations(decl)) == 3

    # Examine each declaration in the vector: 3 partition sorts
    for psort in PNML.declarations(decl)
        # named partition -> partition element -> fe constant
        @test typeof(psort) <: PNML.PartitionSort # is a declaration

        @test PNML.isregistered(reg, pid(psort))
        @test Symbol(PNML.name(psort)) === pid(psort) # name and id are the same.
        @test PNML.sort(psort) isa PNML.UserSort

        partname = PNML.name(psort)
        partsort = PNML.sort(psort)
        part_elements = PNML.elements(psort) # should be iteratable ordered collection
        @test part_elements isa Vector{PNML.PartitionElement}
        for element in part_elements
            # id, name
            @test PNML.isregistered(reg, element.id)
            for term in element.terms
                @test term.declaration isa Symbol
                #!@show term.declaration PNML.isregistered(reg, term.declaration)
            end
        end
    end
end

@testset "exception for Any" begin
    bogus = "this is not valid" # counts as `::Any`
    @test_throws r"^ArgumentError" default_condition(bogus)
    @test_throws "ArgumentError: no default inscription for String" default_inscription(bogus)
    @test_throws "ArgumentError: no default marking for String" default_marking(bogus)
    @test_throws "ArgumentError: no default sort for String" default_sort(bogus)
    @test_throws "ArgumentError: no default sorttype for String" default_sorttype(bogus)
    @test_throws "ArgumentError: expected a PnmlType, got: String" default_bool_term(bogus)
end

@testset "equal sorts" begin
    a = PNML.BoolSort()
    b = PNML.DotSort()
    @test !PNML.equals(a, b)
    @test PNML.equals(a, a)

    for sort1 in InteractiveUtils.subtypes(AbstractSort) # Only 1 layer of abstract!
        isabstracttype(sort1) && continue
        for sort2 in InteractiveUtils.subtypes(AbstractSort) # Only 1 layer of abstract!
            isabstracttype(sort2) && continue
            @test PNML.equals(sort1(), sort2()) isa Bool # mix of true and false
        end
    end
end
