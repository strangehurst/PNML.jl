using PNML, EzXML, ..TestUtils, JET
#using PNML: Maybe
using .PnmlIDRegistrys
using .PnmlIDRegistrys: duplicate_id_warn, duplicate_id_error, duplicate_id_none, reset_registry!
using .PnmlIDRegistrys: PnmlIDRegistry as IDRegistry

@testset "ID registry" for action in (duplicate_id_warn,duplicate_id_error,duplicate_id_none)

    #@test_opt IDRegistry()
    #@test_opt target_modules=(@__MODULE__,) register_id!(reg, :p)

    action = duplicate_id_warn
    @show reg = IDRegistry(; duplicate=action)
    reset_registry!(reg)

    register_id!(reg, "p")
    @test @inferred isregistered_id(reg, "p")
    @test @inferred isregistered_id(reg, :p)
    reset_registry!(reg)
    @test !isregistered_id(reg, "p")
    @test !isregistered_id(reg, :p)
    register_id!(reg, :p)
    register_id!(reg, "q")
end

@testset "test_call"  for action in (duplicate_id_warn,duplicate_id_error,duplicate_id_none)
    @test_call IDRegistry(; duplicate=action)
    reg = IDRegistry(; duplicate=action)
    @test_call register_id!(reg, :p)
    @test_call register_id!(reg, "p")
    @test_call reset_registry!(reg)
end

@testset "duplicate actions" begin
    @test_logs (:warn,"ID already registered: p") duplicate_id_warn(:p)
    @test_throws ArgumentError duplicate_id_error(:p)
    @test @inferred( duplicate_id_none(:p) ) === nothing
end
