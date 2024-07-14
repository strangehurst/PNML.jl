using PNML, ..TestUtils, JET, Logging
const idregistry = ScopedValue{PnmlIDRegistry}()

@testset "ID registry" begin
    @with idregistry => registry() begin
        PnmlIDRegistrys.reset_reg!(idregistry[])
        register_id!(idregistry[], :p1)
        @test @inferred(isregistered(idregistry[], :p1)) == true
        @test isregistered(idregistry[], :p1)
        PnmlIDRegistrys.reset_reg!(idregistry[])
        @test !isregistered(idregistry[], :p1)
        PNML.register_id!(idregistry[], :p1)
        @test isregistered(idregistry[], :p1)
        @show idregistry[]
    end
end

@testset "test_call"  begin
    @test_opt target_modules=(@__MODULE__,) registry()
    @test_call registry()
    @with idregistry => registry() begin
        @test_opt target_modules=(@__MODULE__,) register_id!(idregistry[], :p1)
        @test_opt !isregistered(idregistry[], :p1)
        #@test_opt broken=false PnmlIDRegistrys.reset_reg!(idregistry[], )

        @test_call register_id!(idregistry[], :p)
        @test_call !isregistered(idregistry[], :p1)
        @test_call PnmlIDRegistrys.reset_reg!(idregistry[], )
    end
end
