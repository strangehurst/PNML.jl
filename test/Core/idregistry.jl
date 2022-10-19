using PNML, EzXML, ..TestUtils, JET
#using PNML: Maybe
using .PnmlIDRegistrys
using .PnmlIDRegistrys: duplicate_id_action, reset_registry!

@testset "ID registry" begin
    @test_call IDRegistry()
    reg = IDRegistry()
    @test_call register_id!(reg, :p)
    @test_call register_id!(reg, "p")
    @test_call reset_registry!(reg)
    @test_call duplicate_id_action(:p; action=:bogus)
    
    register_id!(reg, "p")
    @test @inferred isregistered(reg, "p")
    @test @inferred isregistered(reg, :p)
    reset_registry!(reg)
    @test !isregistered(reg, "p")
    @test !isregistered(reg, :p)

    @test_logs (:warn,"ID 'p' already registered") duplicate_id_action(:p)
    @test_logs (:warn,"ID 'p' already registered") duplicate_id_action(:p; action=:warn)
    @test_throws ErrorException duplicate_id_action(:p; action=:error)
    @test @inferred( duplicate_id_action(:p; action=:bogus) ) === nothing
end
