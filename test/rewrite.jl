using PNML, JET
import Metatheory

include("TestUtils.jl")
using .TestUtils

println("REWRITE")
# net = PnmlNet(pntd, :fake)
# PNML.fill_nonhl!(net)
# PNML.fill_labelp!(net)
@show d = DotConstant()
@show Metatheory.rewrite(d, PNML.dot)

@show btrue = PNML.BooleanConstant(true)
@show bfalse = PNML.BooleanConstant(false)

@show Metatheory.rewrite(btrue, PNML.bool_alg)
@show Metatheory.rewrite(bfalse, PNML.bool_alg)
