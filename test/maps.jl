@testset "tagmap" begin
    # Visit every entry in the map.
    @testset "tag $t" for t in keys(PNML.tagmap)
        @test haskey(PNML.tagmap,t)
        @test !isempty(methods(PNML.tagmap[t], (EzXML.Node,))) ||
              !isempty(methods(PNML.tagmap[t], (EzXML.Node, PnmlType)))
    end
    #TODO: Add non-trivial tests.
end

@testset "pnmltype" begin
   #@test_call PNML.PnmlTypes.default_pntd_map()
   @test_call PNML.pnmltype(PnmlCore())
   @test_call pntd_symbol("foo")
   @test_call PNML.pnmltype("pnmlcore")
   @test_call PNML.pnmltype(:pnmlcore)
end
