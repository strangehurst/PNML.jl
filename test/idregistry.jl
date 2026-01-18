using PNML, JET, Logging

include("TestUtils.jl")
using .TestUtils

ctx = PNML.parser_context()
IDRegistrys.reset_reg!(ctx.idregistry)
register_id!(ctx.idregistry, :p1)
@test @inferred(isregistered(ctx.idregistry, :p1)) == true
@test !isempty(ctx.idregistry)
@test length(ctx.idregistry) > 0
@test !isempty(values(ctx.idregistry))

IDRegistrys.reset_reg!(ctx.idregistry)
@test !isregistered(ctx.idregistry, :p1)
register_id!(ctx.idregistry, :p1)
@test isregistered(ctx.idregistry, :p1)
@test_throws PNML.DuplicateIDException PNML.register_id!(ctx.idregistry, :p1)
@test isregistered(ctx.idregistry, :p1) # still registered

@test_opt target_modules=t_modules IDRegistry()
@test_call IDRegistry()
@test_opt target_modules=t_modules register_id!(ctx.idregistry, :p1)
@test_opt !isregistered(ctx.idregistry, :p1)
#@test_opt broken=false IDRegistrys.reset_reg!(ctx.idregistry, )

@test_call register_id!(ctx.idregistry, :p)
@test_call !isregistered(ctx.idregistry, :p1)
@test_call IDRegistrys.reset_reg!(ctx.idregistry, )

@test !isempty(sprint(show, ctx.idregistry))
