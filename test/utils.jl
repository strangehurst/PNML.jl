@testset "MissingID" begin
    mc = PNML.MissingIDCounter()
    count = mc.i
    @test PNML.next_missing_id(mc) == count+1
    @test PNML.next_missing_id(mc) == count+2
    @test PNML.next_missing_id(mc) == count+3
end
#TODO: MissingIDException

@testset "ID registry" begin
    PNML.register_id("p")
    @test PNML.isregistered("p")
    PNML.reset_registry()
    @test !PNML.isregistered("p")
end

