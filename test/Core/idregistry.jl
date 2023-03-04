using PNML, EzXML, ..TestUtils, JET
#using PNML: Maybe
using .PnmlCore

@testset "ID registry" begin
    @test_opt PnmlIDRegistry()
    reg = PnmlIDRegistry()
    @test_opt target_modules=(@__MODULE__,) register_id!(reg, :p)
    PnmlIDRegistrys.reset!(reg)

    register_id!(reg, "p")
    @test @inferred isregistered_id(reg, "p")
    @test @inferred isregistered_id(reg, :p)
    PnmlIDRegistrys.reset!(reg)
    @test !isregistered_id(reg, "p")
    @test !isregistered_id(reg, :p)
    PNML.register_id!(reg, :p)
    PNML.register_id!(reg, "q")
end

@testset "test_call"  begin
    @test_call PnmlIDRegistry()
    @test_opt PnmlIDRegistry()
    reg = PnmlIDRegistry()
    @test_call register_id!(reg, :p)
    @test_call register_id!(reg, "p")
    @test_call PnmlIDRegistrys.reset!(reg)
    #!@test_opt register_id!(reg, :p)
    #!@test_opt register_id!(reg, "p")
    #!@test_opt reset_registry!(reg)
end
