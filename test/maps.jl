@testset "tagmap" begin
    # Visit every entry in the map.
    @testset "tag $t" for t in keys(PNML.tagmap)
        @test haskey(PNML.tagmap,t)
        @test !isempty(methods(PNML.tagmap[t], (EzXML.Node,))) ||
              !isempty(methods(PNML.tagmap[t], (EzXML.Node, PnmlType)))
    end
    #TODO: Add non-trivial tests.
end
