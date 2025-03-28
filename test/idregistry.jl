using PNML, ..TestUtils, JET, Logging
const idregistry = ScopedValue{PnmlIDRegistry}()

@testset "ID registry" begin
    @with idregistry => PnmlIDRegistry() begin # ScopedValue
        PnmlIDRegistrys.reset_reg!(idregistry[])
        register_id!(idregistry[], :p1)
        @test @inferred(isregistered(idregistry[], :p1)) == true
        @test isregistered(idregistry[], :p1)
        PnmlIDRegistrys.reset_reg!(idregistry[])
        @test !isregistered(idregistry[], :p1)
        PNML.register_id!(idregistry[], :p1)
        @test isregistered(idregistry[], :p1)
        #@show idregistry[]
    end

    @test_opt target_modules=(@__MODULE__,) PnmlIDRegistry()
    @test_call PnmlIDRegistry()
    @with idregistry => PnmlIDRegistry() begin
        @test_opt target_modules=(@__MODULE__,) register_id!(idregistry[], :p1)
        @test_opt !isregistered(idregistry[], :p1)
        #@test_opt broken=false PnmlIDRegistrys.reset_reg!(idregistry[], )

        @test_call register_id!(idregistry[], :p)
        @test_call !isregistered(idregistry[], :p1)
        @test_call PnmlIDRegistrys.reset_reg!(idregistry[], )
    end
end
