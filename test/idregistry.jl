using PNML, EzXML, ..TestUtils, JET, Logging

@testset for locker in (nothing, ReentrantLock())
    @testset "ID registry" begin
        reg = registry(locker)
        PnmlIDRegistrys.reset!(reg)

        register_id!(reg, "p1")
        @test @inferred(isregistered(reg, "p1")) == true
        @test @inferred(isregistered(reg, :p1)) == true
        @test isregistered(reg, :p1)
        PnmlIDRegistrys.reset!(reg)
        @test !isregistered(reg, "p1")
        @test !isregistered(reg, :p1)
        PNML.register_id!(reg, "p1")
        @test isregistered(reg, :p1)
    end

    @testset "test_call"  begin
        reg = registry(locker)

        @test_opt target_modules=(@__MODULE__,) registry(locker)
        @test_opt target_modules=(@__MODULE__,) register_id!(reg, :p1)
        @test_opt !isregistered(reg, :p1)
        @test_opt PnmlIDRegistrys.reset!(reg)

        @test_call broken=false registry(locker)
        @test_call register_id!(reg, :p)
        @test_call register_id!(reg, "p")
        @test_call !isregistered(reg, :p1)
        @test_call PnmlIDRegistrys.reset!(reg)
    end
end
