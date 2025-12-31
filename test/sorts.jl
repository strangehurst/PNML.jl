using PNML, ..TestUtils, JET
using InteractiveUtils
using Printf


@testset "parse_sort $pntd" for pntd in PnmlTypes.core_nettypes()
    #println("\nparse_sort $pntd")
    parse_context = PNML.parser_context()::PNML.ParseContext
    ddict = parse_context.ddict
    #@show ddict

    IDRegistrys.reset_reg!(parse_context.idregistry)
    PNML.fill_sort_tag!(parse_context, :X, PNML.NamedSort(:X, "X", PositiveSort(), ddict))
    sortref = parse_sort(xml"<usersort declaration=\"X\"/>", pntd; parse_context)
    sort = to_sort(sortref; parse_context.ddict)::NamedSort |> sortdefinition
    @test sort === PositiveSort()
    @test occursin(r"^PositiveSort", sprint(show, sort))
    @test eltype(sort) == Int64

    IDRegistrys.reset_reg!(parse_context.idregistry)
    sortref = parse_sort(xml"<dot/>", pntd; parse_context)
    sort = to_sort(sortref; parse_context.ddict)::NamedSort |> sortdefinition
    @test sort === DotSort(parse_context.ddict) # not a built-in
    @test occursin(r"^DotSort", sprint(show, sort))
    @test eltype(sort) == Bool

    IDRegistrys.reset_reg!(parse_context.idregistry)
    sortref = parse_sort(xml"<bool/>", pntd; parse_context)
    sort = to_sort(sortref; parse_context.ddict)::NamedSort |> sortdefinition
    @test sort === BoolSort()
    @test occursin(r"^BoolSort", sprint(show, sort))
    @test eltype(sort) == Bool

    IDRegistrys.reset_reg!(parse_context.idregistry)
    sortref = parse_sort(xml"<integer/>", pntd; parse_context)
    sort = to_sort(sortref; parse_context.ddict)::NamedSort |> sortdefinition
    @test sort === IntegerSort()
    @test occursin(r"^IntegerSort", sprint(show, sort))
    @test eltype(sort) == Int64

    IDRegistrys.reset_reg!(parse_context.idregistry)
    sortref = parse_sort(xml"<natural/>", pntd; parse_context)
    sort = to_sort(sortref; parse_context.ddict)::NamedSort |> sortdefinition
    @test sort === NaturalSort()
    @test occursin(r"^NaturalSort", sprint(show, sort))
    @test eltype(sort) == Int64

    IDRegistrys.reset_reg!(parse_context.idregistry)
    sortref = parse_sort(xml"<positive/>", pntd; parse_context)
    sort = to_sort(sortref; parse_context.ddict)::NamedSort |> sortdefinition
    @test sort === PositiveSort()
    @test occursin(r"^PositiveSort", sprint(show, sort))
    @test eltype(sort) == Int64

    IDRegistrys.reset_reg!(parse_context.idregistry)
    sortref = parse_sort(xml"<real/>", pntd; parse_context)
    sort = to_sort(sortref; parse_context.ddict)::NamedSort |> sortdefinition
    @test sort === RealSort()
    @test occursin(r"RealSort", sprint(show, sort))
    @test eltype(sort) == Float64

    IDRegistrys.reset_reg!(parse_context.idregistry)
    sortref = parse_sort(xml"""<cyclicenumeration>
                                <feconstant id="FE0" name="0"/>
                                <feconstant id="FE1" name="1"/>
                            </cyclicenumeration>""", PnmlCoreNet(), :testenum1; parse_context)
    sort = to_sort(sortref; parse_context.ddict)::CyclicEnumerationSort
    #!@test PNML.Sorts.xtag(sort) === :cyclicenumeration
    @test occursin(r"^CyclicEnumerationSort", sprint(show, sort))
    @test eltype(sort) == Symbol

    IDRegistrys.reset_reg!(parse_context.idregistry)
    sortref = parse_sort(xml"""<finiteenumeration>
                                <feconstant id="FE0" name="0"/>
                                <feconstant id="FE1" name="1"/>
                        </finiteenumeration>""", pntd, :testenum2; parse_context)

    sort = to_sort(sortref; parse_context.ddict)::FiniteEnumerationSort
    #!@test PNML.Sorts.xtag(sort) === :finiteenumeration
    @test occursin(r"^FiniteEnumerationSort", sprint(show, sort))
    @test eltype(sort) == Symbol
    #@show @test eltype(sort) == Int64

    IDRegistrys.reset_reg!(parse_context.idregistry)
    sortref = parse_sort(xml"<finiteintrange start=\"2\" end=\"3\"/>", pntd, :testfiniteintrange; parse_context)

    sort = to_sort(sortref; parse_context.ddict)::FiniteIntRangeSort
    #!@test PNML.Sorts.xtag(sort) === :finiteintrange
    @test occursin(r"^FiniteIntRangeSort", sprint(show, sort))
    @test eltype(sort) == Int64

    # productsort is expected to be enclosed in a namedsort
    @test_logs(match_mode=:any, (:warn, r"^ISO 15909 Standard allows.*"),
               parse_sort(xml"""<productsort/>""", pntd, :emptyproduct, "emptyproduct"; parse_context))

    IDRegistrys.reset_reg!(parse_context.idregistry)
    PNML.fill_nonhl!(parse_context) # should be redundant, but harmless
    sortref = parse_sort(xml"""<productsort>
                                <integer/>
                                <integer/>
                        </productsort>""", pntd, :redundant, "redundant"; parse_context)
    sort = to_sort(sortref; parse_context.ddict)::ProductSort
    @test occursin(r"^ProductSort", sprint(show, sort))
    @test eltype(sort) == Any #! TODO XXX

    IDRegistrys.reset_reg!(parse_context.idregistry)
    PNML.fill_nonhl!(parse_context) # should be redundant, but harmless
    PNML.fill_sort_tag!(parse_context, :speed, NamedSort(:speed, "speed", PositiveSort(), ddict))
    PNML.fill_sort_tag!(parse_context, :distance, NamedSort(:distance, "dictance", NaturalSort(), ddict))
    sortref= parse_sort(xml"""<productsort>
                        <usersort declaration="speed"/>
                        <usersort declaration="distance"/>
                        </productsort>""", pntd, :someproduct, "someproduct"; parse_context)
    sort = to_sort(sortref; parse_context.ddict)::ProductSort
    @test sort isa ProductSort
    @test occursin(r"^ProductSort", sprint(show, sort))
    @test eltype(sort) == Any #! TODO XXX

    # IDRegistrys.reset_reg!(ctx.idregistry)
    # sort = parse_sort(xml"""<productsort>
    #                            <usersort declaration="id1"/>
    #                            <natural/>
    #                         </productsort>""", pntd)::ProductSort
    #  @test_logs sprint(show, sort)
    # @test_logs eltype(sort)

    IDRegistrys.reset_reg!(parse_context.idregistry)
    PNML.fill_nonhl!(parse_context) # should be redundant, but harmless
    PNML.fill_sort_tag!(parse_context, :duck, NamedSort(:duck, "duck", PositiveSort(), ddict))

    sortref = parse_sort(xml"""<multisetsort>
                                <usersort declaration="duck"/>
                            </multisetsort>""", pntd; parse_context)
    sort = to_sort(sortref; parse_context.ddict)#::MultisetSort
    PNML.fill_sort_tag!(parse_context, :amultiset, sort) #~ test of method needed here
    @test occursin(r"^MultisetSort", sprint(show, sort))
    @test eltype(sort) == Any

    #^ ArbitrarySort

    IDRegistrys.reset_reg!(parse_context.idregistry)
    PNML.fill_nonhl!(parse_context) # should be redundant, but harmless
    sort = ArbitrarySort(:arbsort, "ArbSort", ddict)
    PNML.fill_sort_tag!(parse_context, :arbsort, sort) #~ test of method needed here
    #!@test occursin(r"^ArbitrarySort", sprint(show, sort))
    #!@show @test_logs eltype(sort)
    #!@show parse_context.ddict

    #^ String

    IDRegistrys.reset_reg!(parse_context.idregistry)
    sortref = parse_sort(xml"<string/>", pntd; parse_context)
    sort = to_sort(sortref; parse_context.ddict)::StringSort
    @test sort isa StringSort
    @test PNML.sortelements(sort) == ("",)
    @test occursin(r"^StringSort", sprint(show, sort))
    @test eltype(sort) == String
    @test first(PNML.sortelements(sort)) == ""
    #TODO PartitionSort
end
