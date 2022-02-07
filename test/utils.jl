#TODO: MissingIDException

@testset "ID registry" begin
    reg = PNML.IDRegistry()
    PNML.register_id!(reg, "p")
    @test PNML.isregistered(reg, "p")
    PNML.reset_registry!(reg)
    @test !PNML.isregistered(reg, "p")
end

