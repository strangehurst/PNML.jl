using PNML, ..TestUtils, JET, Metatheory

println("REWRITE")
@with PNML.idregistry => PnmlIDRegistry() begin
    ddict = PNML.decldict(PNML.idregistry[])
    @show d = DotConstant(ddict)
    @show Metatheory.rewrite(d, PNML.dot)

    @show btrue = PNML.BooleanConstant("true", ddict)
    @show bfalse = PNML.BooleanConstant("false", ddict)

    @show Metatheory.rewrite(btrue, PNML.bool_alg)
    @show Metatheory.rewrite(bfalse, PNML.bool_alg)
end
