using PNML, ..TestUtils, JET, Metatheory

println("REWRITE")
@with PNML.idregistry => PnmlIDRegistry() PNML.DECLDICT => PNML.DeclDict() begin
    PNML.fill_nonhl!()
    @show d = DotConstant()
    @show Metatheory.rewrite(d, PNML.dot)

    @show btrue = PNML.BooleanConstant("true")
    @show bfalse = PNML.BooleanConstant("false")

    @show Metatheory.rewrite(btrue, PNML.bool_alg)
    @show Metatheory.rewrite(bfalse, PNML.bool_alg)
end
