using PNML, EzXML, ..TestUtils, JET
@testset for locker in (nothing, ReentrantLock())
    #println("registry locker = $locker")
    @testset "ID registry" begin
        #@test_opt  registry()
        reg = registry(locker)
        @test_opt target_modules=(@__MODULE__,) register_id!(reg, :p)
        PnmlIDRegistrys.reset!(reg)

        register_id!(reg, "p")
        @test @inferred(isregistered(reg, "p")) == true
        @test @inferred(isregistered(reg, :p)) == true
        PnmlIDRegistrys.reset!(reg)
        @test !isregistered(reg, "p")
        @test !isregistered(reg, :p)
        PNML.register_id!(reg, "p")
        PNML.register_id!(reg, :p)
    end

    @testset "test_call"  begin
        @test_call broken=false registry()
        reg = registry(locker)
        @test_call register_id!(reg, :p)
        @test_call register_id!(reg, "p")
        @test_call PnmlIDRegistrys.reset!(reg)
        #!@test_opt register_id!(reg, :p)
        #!@test_opt register_id!(reg, "p")
        #!@test_opt reset_registry!(reg)
    end
end
