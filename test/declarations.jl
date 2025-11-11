using PNML, ..TestUtils, JET
using InteractiveUtils
using Printf

#!
#! TODO add tests for variable declarations
#!

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

@testset "parse_sort $pntd" for pntd in PnmlTypes.core_nettypes()
    #println("\nparse_sort $pntd")
    parse_context = PNML.parser_context()::PNML.ParseContext
    ddict = parse_context.ddict
    #@show ddict

    PnmlIDRegistrys.reset_reg!(parse_context.idregistry)
    PNML.fill_sort_tag!(parse_context, :X, PNML.NamedSort(:X, "X", PositiveSort(), ddict))
    sortref = parse_sort(xml"<usersort declaration=\"X\"/>", pntd; parse_context)
    #@show ddict #!debug
    sort = to_sort(sortref; parse_context.ddict)::NamedSort |> sortdefinition
    @test sort === PositiveSort()
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    PnmlIDRegistrys.reset_reg!(parse_context.idregistry)
    sortref = parse_sort(xml"<dot/>", pntd; parse_context)
    sort = to_sort(sortref; parse_context.ddict)::NamedSort |> sortdefinition
    @test sort === DotSort(parse_context.ddict) # not a built-in
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    PnmlIDRegistrys.reset_reg!(parse_context.idregistry)
    sortref = parse_sort(xml"<bool/>", pntd; parse_context)
    sort = to_sort(sortref; parse_context.ddict)::NamedSort |> sortdefinition
    @test sort === BoolSort()
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    PnmlIDRegistrys.reset_reg!(parse_context.idregistry)
    sortref = parse_sort(xml"<integer/>", pntd; parse_context)
    sort = to_sort(sortref; parse_context.ddict)::NamedSort |> sortdefinition
    @test sort === IntegerSort()
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    PnmlIDRegistrys.reset_reg!(parse_context.idregistry)
    sortref = parse_sort(xml"<natural/>", pntd; parse_context)
    sort = to_sort(sortref; parse_context.ddict)::NamedSort |> sortdefinition
    @test sort === NaturalSort()
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    PnmlIDRegistrys.reset_reg!(parse_context.idregistry)
    sortref = parse_sort(xml"<positive/>", pntd; parse_context)
    sort = to_sort(sortref; parse_context.ddict)::NamedSort |> sortdefinition
    @test sort === PositiveSort()
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    PnmlIDRegistrys.reset_reg!(parse_context.idregistry)
    sortref = parse_sort(xml"<real/>", pntd; parse_context)
    sort = to_sort(sortref; parse_context.ddict)::NamedSort |> sortdefinition
    @test sort === RealSort()
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    #println()
    PnmlIDRegistrys.reset_reg!(parse_context.idregistry)
    sortref = parse_sort(xml"""<cyclicenumeration>
                                <feconstant id="FE0" name="0"/>
                                <feconstant id="FE1" name="1"/>
                            </cyclicenumeration>""", PnmlCoreNet(), :testenum1; parse_context)
    sort = to_sort(sortref; parse_context.ddict):: CyclicEnumerationSort
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    PnmlIDRegistrys.reset_reg!(parse_context.idregistry)
    sortref = parse_sort(xml"""<finiteenumeration>
                                <feconstant id="FE0" name="0"/>
                                <feconstant id="FE1" name="1"/>
                        </finiteenumeration>""", pntd, :testenum2; parse_context)

    sort = to_sort(sortref; parse_context.ddict)::FiniteEnumerationSort
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    PnmlIDRegistrys.reset_reg!(parse_context.idregistry)
    sortref = parse_sort(xml"<finiteintrange start=\"2\" end=\"3\"/>", pntd, :testfiniteintrange; parse_context)

    sort = to_sort(sortref; parse_context.ddict)::FiniteIntRangeSort
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    # productsort is expected to be enclosed in a namedsort
    @test_logs(match_mode=:any, (:warn, r"^ISO 15909 Standard allows.*"),
               parse_sort(xml"""<productsort/>""", pntd, :emptyproduct, "emptyproduct"; parse_context))

    PnmlIDRegistrys.reset_reg!(parse_context.idregistry)
    PNML.fill_nonhl!(parse_context) # should be redundant, but harmless
    sortref = parse_sort(xml"""<productsort>
                                <integer/>
                                <integer/>
                        </productsort>""", pntd, :redundant, "redundant"; parse_context)
    sort = to_sort(sortref; parse_context.ddict)::ProductSort
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    PnmlIDRegistrys.reset_reg!(parse_context.idregistry)
    PNML.fill_nonhl!(parse_context) # should be redundant, but harmless
    PNML.fill_sort_tag!(parse_context, :speed, NamedSort(:speed, "speed", PositiveSort(), ddict))
    PNML.fill_sort_tag!(parse_context, :distance, NamedSort(:distance, "dictance", NaturalSort(), ddict))
    sortref= parse_sort(xml"""<productsort>
                        <usersort declaration="speed"/>
                        <usersort declaration="distance"/>
                        </productsort>""", pntd, :someproduct, "someproduct"; parse_context)
    sort = to_sort(sortref; parse_context.ddict)::ProductSort
    @test sort isa ProductSort
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    # PnmlIDRegistrys.reset_reg!(ctx.idregistry)
    # sort = parse_sort(xml"""<productsort>
    #                            <usersort declaration="id1"/>
    #                            <natural/>
    #                         </productsort>""", pntd)::ProductSort
    #  @test_logs sprint(show, sort)
    # @test_logs eltype(sort)

    PnmlIDRegistrys.reset_reg!(parse_context.idregistry)
    PNML.fill_nonhl!(parse_context) # should be redundant, but harmless
    PNML.fill_sort_tag!(parse_context, :duck, NamedSort(:duck, "duck", PositiveSort(), ddict))

    sortref = parse_sort(xml"""<multisetsort>
                                <usersort declaration="duck"/>
                            </multisetsort>""", pntd; parse_context)
    #@show parse_context.ddict
    sort = to_sort(sortref; parse_context.ddict)#::MultisetSort
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    PnmlIDRegistrys.reset_reg!(parse_context.idregistry)
    PNML.fill_nonhl!(parse_context) # should be redundant, but harmless
    sortref = parse_sort(xml"""<multisetsort>
                                <natural/>
                            </multisetsort>""", pntd; parse_context)
    sort = to_sort(sortref; parse_context.ddict)::MultisetSort
    @test_logs sprint(show, sort)
    @test_logs eltype(sort)

    #TODO PartitionSort
    #TODO ArbitrarySort
end

@testset "empty declarations $pntd" for pntd in PnmlTypes.core_nettypes()
    ctx = PNML.Parser.parser_context()::PNML.ParseContext

        decl = parse_declaration!(ctx, xml"""<declaration key="test empty">
                <structure><declarations></declarations></structure>
            </declaration>""", pntd)::Declaration

        #@test ddict == decl
        @test length(decl) == 7 # nothing in <declarations>
        @test !isempty(decl)
        @test PNML.graphics(decl) === nothing
        @test PNML.toolinfos(decl) === nothing

        @test_opt PNML.decldict(decl)
        @test_opt PNML.graphics(decl)
        @test_opt PNML.toolinfos(decl)

        @test_call PNML.decldict(decl)
        @test_call PNML.graphics(decl)
        @test_call PNML.toolinfos(decl)
end

@testset "namedsort declaration $pntd" for pntd in PnmlTypes.core_nettypes()
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
                <!-- namedoperator -->
                <!-- arbitrarysort, arbitraryoperator -->
            </declarations>
        </structure>
        <graphics>	<position x="11" y="22" /> </graphics>
        <toolspecific tool="sometool" version="6.6">
            <tokengraphics> <tokenposition x="6" y="9"/> </tokengraphics>
        </toolspecific>
        <unknownchild />
    </declaration>
    """

    ctx = PNML.Parser.parser_context()::PNML.ParseContext

        base_decl_length = length(PNML.namedsorts(ctx.ddict))
        decl = parse_declaration!(ctx, node, pntd)::PNML.Declaration # Add 3 declarations.

        #@show decl PNML.parse_context.idregistry
        @test length(PNML.namedsorts(ctx.ddict)) == base_decl_length + 3
        #println()

        for nsort in values(PNML.namedsorts(ctx.ddict))
            # NamedSorts are declarations. They give an identity to a built-in (or arbitrary)
            # by wraping an ID of a declared sort.
            # named sort -> cyclic enumeration -> fe constant
            #!@test typeof(nsort) <: PNML.NamedSort # is a declaration
            #@show nsort pid(nsort)
            @test isregistered(ctx.idregistry, pid(nsort))
            #!@test Symbol(PNML.name(nsort)) === pid(nsort) # NOT TRUE! name and id are the same.
            #!@test PNML.sortof(nsort) isa PNML.CyclicEnumerationSort
            #@test PNML.elements(PNML.sortof(nsort)) isa Vector{PNML.FEConstant}

            sortname = PNML.name(nsort)
            cesort   = PNML.sortdefinition(nsort)
            feconsts = PNML.sortelements(cesort) # should be iteratable ordered collection
            feconsts isa Vector{PNML.FEConstant}
            #!@test length(feconsts) == 2
            # for fec in feconsts
            #     @test fec isa PNML.FEConstant
            #     @test fec.id isa Symbol
            #     @test fec.name isa AbstractString
            #     @test isregistered(fec.id)

            #     @test endswith(string(fec.id), fec.name)
            # end
        end
end


@testset "partition declaration $pntd" for pntd in PnmlTypes.core_nettypes()
    node = xml"""
    <declaration>
        <structure>
            <declarations>
                <namedsort id="pluck" name="PLUCK">
                    <finiteenumeration>
                        <feconstant id="b1" name="b1" />
                        <feconstant id="b2" name="b2" />
                        <feconstant id="b3" name="b3" />
                   </finiteenumeration>
                </namedsort>
                <namedsort id="pluck2" name="PLUCK2">
                    <finiteenumeration>
                        <feconstant id="b4" name="b4" />
                        <feconstant id="b5" name="b5" />
                        <feconstant id="b6" name="b6" />
                   </finiteenumeration>
                </namedsort>

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

    ctx = PNML.Parser.parser_context()::PNML.ParseContext
        decl = parse_declaration!(ctx, node, pntd)
        @test typeof(decl) <: Declaration

        # Examine 3 partition sorts
        for psort in values(PNML.partitionsorts(decldict(decl)))
            # named partition -> partition element -> fe constant
            @test typeof(psort) <: PartitionSort # is a declaration

            @test PNML.isregistered(ctx.idregistry, pid(psort))
            @test Symbol(PNML.name(psort)) === pid(psort) # name and id are the same.
            #@show psort
            partname = PNML.name(psort)
            partsort = PNML.Declarations.sortdefinition(psort)
            part_elements = PNML.sortelements(psort)::Vector{PartitionElement}

            for element in part_elements
                @test PNML.isregistered(ctx.idregistry, pid(element))
            end
        end
end

const nonsimple_sorts = (MultisetSort, ProductSort,
    CyclicEnumerationSort, FiniteEnumerationSort, FiniteIntRangeSort)

_sorts() = _subtypes(AbstractSort)

@testset "equal sorts" begin
    println("============================")
    println(" TODO equal sorts: $(_sorts())")
    println("============================")
    #TODO PartitionSort is confused - a SortDeclaration
    # for s in [x for x in _sorts() if x ∉ nonsimple_sorts]
    #     println(s)
    #     a = s()
    #     b = s()
    #     @test PNML.Sorts.equals(a, a)
    # end

    # for sorta in [x for x in _sorts() if x ∉ nonsimple_sorts]
    #     for sortb in [x for x in _sorts() if x ∉ nonsimple_sorts]
    #         a = sorta()
    #         b = sortb()
    #         #println(repr(a), " == ", repr(b), " --> ", PNML.Sorts.equals(a, b), ", ", (a == b))
    #         sorta != sortb && @test a != b && !PNML.Sorts.equals(a, b)
    #         sorta == sortb && @test PNML.Sorts.equals(a, b)::Bool && (a == b)
    #     end
    # end

    #TODO Add tests for enumerated sorts, et al., with content.
    # MultisetSort
    println("""

    for sorta in [x for x in _sorts() if x ∉ nonsimple_sorts]
        for sortb in [x for x in _sorts() if x ∉ nonsimple_sorts]
            a = PNML.MultisetSort(sorta())
            b = PNML.MultisetSort(sortb())
            sorta != sortb && @test a != b && !PNML.equals(a, b)
            sorta == sortb && @test PNML.equals(a, b)::Bool && (a == b)
        end
    end
    """)
    println("============================")
end
