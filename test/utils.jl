@testset "MissingID" begin
    mc = PNML.MissingIDCounter()
    count = mc.i
    @test PNML.next_missing_id(mc) == count+1
    @test PNML.next_missing_id(mc) == count+2
    @test PNML.next_missing_id(mc) == count+3
end
#TODO: MissingIDException
