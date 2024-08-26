using PNML, ..TestUtils, JET, Metatheory

println("REWRITE")
@show d = DotConstant()
@show rewrite(d, PNML.dot)

@show btrue = PNML.BooleanConstant("true")
@show bfalse = PNML.BooleanConstant("false")

@show rewrite(btrue, PNML.bool_alg)
@show rewrite(bfalse, PNML.bool_alg)
