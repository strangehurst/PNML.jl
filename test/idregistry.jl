using PNML, EzXML, ..TestUtils, JET, Logging

@testset for locker in (nothing, ReentrantLock())
    #println("registry locker = $locker")
    @testset "ID registry" begin
        #@test_opt  registry()
        reg = registry(locker)
        @test_opt target_modules=(@__MODULE__,) register_id!(reg, :p1)
        PnmlIDRegistrys.reset!(reg)

        register_id!(reg, "p1")
        @test @inferred(isregistered(reg, "p1")) == true
        @test @inferred(isregistered(reg, :p1)) == true
        PnmlIDRegistrys.reset!(reg)
        @test !isregistered(reg, "p1")
        @test !isregistered(reg, :p1)
        PNML.register_id!(reg, "p1")
        PNML.register_id!(reg, :p1)
    end

    @testset "test_call"  begin
        @test_call broken=false registry(locker)
        reg = registry(locker)
        @test_call register_id!(reg, :p)
        @test_call register_id!(reg, "p")
        @test_call PnmlIDRegistrys.reset!(reg)
        #!@test_opt register_id!(reg, :p)
        #!@test_opt register_id!(reg, "p")
        #!@test_opt reset_registry!(reg)
    end
end
