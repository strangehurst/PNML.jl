using PNML, EzXML, ..TestUtils, JET
#using PNML: Maybe
using .PnmlIDRegistrys
using .PnmlIDRegistrys: duplicate_id_action, reset_registry!
using .PnmlIDRegistrys: PnmlIDRegistry as IDRegistry

@testset "ID registry" begin
    reg = IDRegistry()

    #@test_opt IDRegistry()
    #@test_opt target_modules=(@__MODULE__,) register_id!(reg, :p)
    #@test_opt target_modules=(@__MODULE__,) register_id!(reg, "p")
    #@test_opt target_modules=(@__MODULE__,) reset_registry!(reg)
    #@test_opt target_modules=(@__MODULE__,) duplicate_id_action(:p; action=:bogus)

    @test_call IDRegistry()
    @test_call register_id!(reg, :p)
    @test_call register_id!(reg, "p")
    @test_call reset_registry!(reg)
    @test_call duplicate_id_action(:p; action=:bogus)

    register_id!(reg, "p")
    @test @inferred isregistered_id(reg, "p")
    @test @inferred isregistered_id(reg, :p)
    reset_registry!(reg)
    @test !isregistered_id(reg, "p")
    @test !isregistered_id(reg, :p)

    @test_logs (:warn,"ID already registered: p") duplicate_id_action(:p)
    @test_logs (:warn,"ID already registered: p") duplicate_id_action(:p; action=:warn)
    @test_throws ArgumentError duplicate_id_action(:p; action=:error)
    @test @inferred( duplicate_id_action(:p; action=:bogus) ) === nothing
end
