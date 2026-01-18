using PNML, JET, NamedTupleTools, OrderedCollections
using EzXML: EzXML
using XMLDict: XMLDict

include("TestUtils.jl")
using .TestUtils

@testset "type $pntd" for pntd in PnmlTypes.all_nettypes(ishighlevel)
    # Add usersort, namedsort duo as test context.
    ctx = PNML.parser_context()
    PNML.namedsorts(ctx.ddict)[:N2] = PNML.NamedSort(:N2, "N2", DotSort(ctx.ddict), ctx.ddict)

    n1 = xml"""
<type>
    <text>N2</text>
    <structure> <usersort declaration="N2"/> </structure>
</type>
    """
    typ = PNML.Parser.parse_sorttype(n1, pntd; parse_context=ctx, parentid=:foobar)::SortType
    @test text(typ) == "N2"
    @test PNML.sortref(typ) isa PNML.AbstractSortRef # wrapping DotSort
    @test PNML.sortof(typ) == DotSort(ctx.ddict) #! does the name of a sort affect equal Sorts?
    @test PNML.has_graphics(typ) == false
    @test !occursin("Graphics", sprint(show, typ))
end
