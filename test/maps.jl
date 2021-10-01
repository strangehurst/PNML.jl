@testset "applymap" begin
    @testset "apply $t" for t in keys(PNML.applymap)
        @test haskey(PNML.applymap,t)
        @test !isempty(methods(PNML.applymap[t]))
    end
end

@testset "tagmap" begin
    # Visit every entry in the map.
    @testset "tag $t" for t in keys(PNML.tagmap)
        @test haskey(PNML.tagmap,t)
        @test !isempty(methods(PNML.tagmap[t], (EzXML.Node,)))
    end
    #TODO: Add non-trivial tests.
end

@testset "verifymap" begin
    @testset "tag $t" for t in keys(PNML.verifymap)
        @test haskey(PNML.verifymap,t)
        @test !isempty(methods(PNML.verifymap[t], (EzXML.Node,)))
    end
end

