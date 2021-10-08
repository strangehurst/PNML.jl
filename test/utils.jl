@testset "MissingID" begin
    mc = PNML.MissingIDCounter()
    count = mc.i
    @test PNML.next_missing_id(mc) == count+1
    @test PNML.next_missing_id(mc) == count+2
    @test PNML.next_missing_id(mc) == count+3
end
#TODO: MissingIDException

@testset "ID registry" begin
    reg = PNML.IDRegistry()
    PNML.register_id!(reg, "p")
    @test PNML.isregistered(reg, "p")
    PNML.reset_registry!(reg)
    @test !PNML.isregistered(reg, "p")
end

