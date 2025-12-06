using PNML, ..TestUtils, JET
import Metatheory

println("REWRITE")
ctx = PNML.parser_context()
@show d = DotConstant(ctx.ddict)
@show Metatheory.rewrite(d, PNML.dot)

@show btrue = PNML.BooleanConstant("true", ctx.ddict)
@show bfalse = PNML.BooleanConstant("false", ctx.ddict)

@show Metatheory.rewrite(btrue, PNML.bool_alg)
@show Metatheory.rewrite(bfalse, PNML.bool_alg)
