@testset "labels" begin
    # Exersize the :labels of a PnmlDict
    labels = PnmlDict[]
    @testset "tag $t" for t in keys(PNML.tagmap)
        @test haskey(PNML.tagmap,t)
        @test !isempty(methods(PNML.tagmap[t], (EzXML.Node,)))
    end
    #TODO: Add non-trivial tests.
end
