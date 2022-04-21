@testset "ID registry" begin
    reg = PNML.IDRegistry()
    PNML.register_id!(reg, "p")
    @test PNML.isregistered(reg, "p")
    @test PNML.isregistered(reg, :p)
    PNML.reset_registry!(reg)
    @test !PNML.isregistered(reg, "p")
    @test !PNML.isregistered(reg, :p)

    @test_logs (:warn,"ID 'p' already registered") PNML.duplicate_id_action(:p)
    @test_logs (:warn,"ID 'p' already registered") PNML.duplicate_id_action(:p; action=:warn)
    @test_throws ErrorException PNML.duplicate_id_action(:p; action=:error)
    @test PNML.duplicate_id_action(:p; action=:bogus) === nothing
end

