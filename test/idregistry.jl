using PNML, ..TestUtils, JET, Logging

@testset "ID registry" begin
    ctx = PNML.parser_context()
    PnmlIDRegistrys.reset_reg!(ctx.idregistry)
    register_id!(ctx.idregistry, :p1)
    @test @inferred(isregistered(ctx.idregistry, :p1)) == true
    @test isregistered(ctx.idregistry, :p1)
    PnmlIDRegistrys.reset_reg!(ctx.idregistry)
    @test !isregistered(ctx.idregistry, :p1)
    PNML.register_id!(ctx.idregistry, :p1)
    @test isregistered(ctx.idregistry, :p1)
    #@show idregistry

    @test_opt target_modules=(@__MODULE__,) PnmlIDRegistry()
    @test_call PnmlIDRegistry()
    @test_opt target_modules=(@__MODULE__,) register_id!(ctx.idregistry, :p1)
    @test_opt !isregistered(ctx.idregistry, :p1)
    #@test_opt broken=false PnmlIDRegistrys.reset_reg!(ctx.idregistry, )

    @test_call register_id!(ctx.idregistry, :p)
    @test_call !isregistered(ctx.idregistry, :p1)
    @test_call PnmlIDRegistrys.reset_reg!(ctx.idregistry, )
end
