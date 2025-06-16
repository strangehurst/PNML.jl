using PNML, ..TestUtils, JET, NamedTupleTools, AbstractTrees
using EzXML: EzXML
using XMLDict: XMLDict

# See PnmlExpr
_op() = (; args=(PNML.Bag(UserSort(:pro), 1, PNML.NumberEx(UserSort(:natural), 1)),
                 PNML.Bag(UserSort(:pro), 2, PNML.NumberEx(UserSort(:natural), 1)), ))

const pntd = HLCoreNet()
const ctx = PNML.parser_context()
const ddict = ctx.ddict
const varsub = NamedTuple()

@testset "multiset add $pntd" begin
    b1 = PNML.Bag(UserSort(:pro, ddict), 1, PNML.NumberEx(UserSort(:natural, ddict), 1))
    b2 = PNML.Bag(UserSort(:pro, ddict), 2, PNML.NumberEx(UserSort(:natural, ddict), 1))
    #@show b1 b2

    a = PNML.Add([b1, b2])
    @show a
    ex = PNML.toexpr(a, varsub, ddict)
    #@show  ex
    val = eval(ex)
    @show val
    @test val == eval(PNML.toexpr(b1, varsub, ddict)) + eval(PNML.toexpr(b2, varsub, ddict))
end
println()

@testset "booean not $pntd" begin
    b1 = PNML.BooleanEx(PNML.BooleanConstant(true, ddict))
    b2 = PNML.BooleanEx(PNML.BooleanConstant(false, ddict))
    #@show b1 b2

    a = PNML.Not([b1, b2])
    @show a
    ex = PNML.toexpr(a, varsub, ddict)
    #@show  ex
    val = eval(ex)
    @show val
    @test val == false
end

# And, Or
