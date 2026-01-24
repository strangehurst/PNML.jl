using PNML, JET, InteractiveUtils, Printf

include("TestUtils.jl")
using .TestUtils
using PNML: fill_sort_tag!, fill_nonhl!, fill_labelp!

@testset "parser_context" begin
    println("parser_context")
    pntd = PnmlCoreNet()
    ctx = parser_context()::ParseContext
    ddict = ctx.ddict
    @test_call target_modules=t_modules NamedSort(:X, "X", PositiveSort(), ddict)
    @test_opt target_modules=t_modules function_filter=pff NamedSort(:X, "X", PositiveSort(), ddict)

    @test_call target_modules=t_modules fill_sort_tag!(ctx, :X, NamedSort(:X, "X", PositiveSort(), ddict))
    @test_opt target_modules=t_modules function_filter=pff fill_sort_tag!(ctx, :X, NamedSort(:X, "X", PositiveSort(), ddict))
    builtin_sorts = ((:integer, "Integer", Sorts.IntegerSort()),
                    (:natural, "Natural", Sorts.NaturalSort()),
                    (:positive, "Positive", Sorts.PositiveSort()),
                    (:real, "Real", Sorts.RealSort()),
                    (:bool, "AbstractSortRefBool", Sorts.BoolSort()),
                    (:null, "Null", Sorts.NullSort()),
                    (:dot, "Dot", Sorts.DotSort(ctx.ddict)), #users can overrid
                    )
    for (tag, name, sort) in builtin_sorts
        #@show typeof(sort)
        nsort = NamedSort(tag, name, sort, ctx.ddict)
        @test_call target_modules=t_modules fill_sort_tag!(ctx, tag, nsort)
        @test_opt target_modules=t_modules function_filter=pff fill_sort_tag!(ctx, tag, nsort)
    end


    @test_call target_modules=t_modules ParseContext()
    @test_opt target_modules=t_modules function_filter=pff ParseContext()

    let ctx = @inferred ParseContext()
        @test_call target_modules=t_modules  fill_nonhl!(ctx)
        @test_call target_modules=t_modules  fill_labelp!(ctx)
        @test_opt target_modules=t_modules function_filter=pff  fill_nonhl!(ctx)
        @test_opt target_modules=t_modules function_filter=pff  fill_labelp!(ctx)
    end

    @test_call target_modules=t_modules parser_context()
    @test_opt target_modules=t_modules function_filter=pff parser_context()
end

@testset "parse_sort $pntd" for pntd in PnmlTypes.core_nettypes()
    #println("\nparse_sort $pntd")
    parse_context = @inferred ParseContext parser_context()
    ddict = parse_context.ddict
    #@show ddict

    IDRegistrys.reset_reg!(parse_context.idregistry)
    @inferred fill_sort_tag!(parse_context, :X, NamedSort(:X, "X", PositiveSort(), ddict))
    sortref = @inferred SortRef.Type parse_sort(xml"<usersort declaration=\"X\"/>", pntd; parse_context)
    ts = @inferred NamedSort to_sort(sortref; parse_context.ddict)
    sort = @inferred sortdefinition(ts)
    @test sort === @inferred PositiveSort()
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
    @test occursin(r"^CyclicEnumerationSort", sprint(show, sort))
    @test eltype(sort) == Symbol

    IDRegistrys.reset_reg!(parse_context.idregistry)
    sortref = parse_sort(xml"""<finiteenumeration>
                                <feconstant id="FE0" name="0"/>
                                <feconstant id="FE1" name="1"/>
                        </finiteenumeration>""", pntd, :testenum2; parse_context)

    sort = to_sort(sortref; parse_context.ddict)::FiniteEnumerationSort
    @test occursin(r"^FiniteEnumerationSort", sprint(show, sort))
    @test eltype(sort) == Symbol
    #@show @test eltype(sort) == Int64

    IDRegistrys.reset_reg!(parse_context.idregistry)
    sortref = parse_sort(xml"<finiteintrange start=\"2\" end=\"3\"/>", pntd, :testfiniteintrange; parse_context)

    sort = to_sort(sortref; parse_context.ddict)::FiniteIntRangeSort
    @test occursin(r"^FiniteIntRangeSort", sprint(show, sort))
    @test eltype(sort) == Int64

    # productsort is expected to be enclosed in a namedsort
    @test_logs(match_mode=:any, (:warn, r"^ISO 15909 Standard allows.*"),
               parse_sort(xml"""<productsort/>""", pntd, :emptyproduct, "emptyproduct"; parse_context))

    IDRegistrys.reset_reg!(parse_context.idregistry)
    fill_nonhl!(parse_context) # should be redundant, but harmless
    sortref = parse_sort(xml"""<productsort>
                                <integer/>
                                <integer/>
                        </productsort>""", pntd, :redundant, "redundant"; parse_context)
    sort = to_sort(sortref; parse_context.ddict)::ProductSort
    @test occursin(r"^ProductSort", sprint(show, sort))
    @test eltype(sort) == Any #! TODO XXX

    IDRegistrys.reset_reg!(parse_context.idregistry)
    fill_nonhl!(parse_context) # should be redundant, but harmless
    fill_sort_tag!(parse_context, :speed, NamedSort(:speed, "speed", PositiveSort(), ddict))
    fill_sort_tag!(parse_context, :distance, NamedSort(:distance, "dictance", NaturalSort(), ddict))
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
    fill_nonhl!(parse_context) # should be redundant, but harmless
    fill_sort_tag!(parse_context, :duck, NamedSort(:duck, "duck", PositiveSort(), ddict))

    sortref = parse_sort(xml"""<multisetsort>
                                <usersort declaration="duck"/>
                            </multisetsort>""", pntd; parse_context)
    sort = to_sort(sortref; parse_context.ddict)#::MultisetSort
    fill_sort_tag!(parse_context, :amultiset, sort) #~ test of method needed here
    @test occursin(r"^MultisetSort", sprint(show, sort))
    @test eltype(sort) == Any

    #^ ArbitrarySort

    IDRegistrys.reset_reg!(parse_context.idregistry)
    fill_nonhl!(parse_context) # should be redundant, but harmless
    sort = ArbitrarySort(:arbsort, "ArbSort", ddict)
    fill_sort_tag!(parse_context, :arbsort, sort) #~ test of method needed here
    #!@test occursin(r"^ArbitrarySort", sprint(show, sort))
    #!@show @test_logs eltype(sort)
    #!@show parse_context.ddict

    #^ String

    IDRegistrys.reset_reg!(parse_context.idregistry)
    sortref = parse_sort(xml"<string/>", pntd; parse_context)
    sort = to_sort(sortref; parse_context.ddict)::StringSort
    @test sort isa StringSort
    @test sortelements(sort) == ("",)
    @test occursin(r"^StringSort", sprint(show, sort))
    @test eltype(sort) == String
    @test first(sortelements(sort)) == ""
    #TODO PartitionSort
end
