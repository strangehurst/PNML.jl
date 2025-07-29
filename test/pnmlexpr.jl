using PNML, ..TestUtils, JET, NamedTupleTools, AbstractTrees
using EzXML: EzXML
using XMLDict: XMLDict

const pntd = HLCoreNet()
const ctx = PNML.parser_context()
const ddict = ctx.ddict
const varsub = NamedTuple()

@testset "multiset add $pntd" begin
    # When will it be noticed that `:pro` is not a valid REFID?
    b1 = PNML.Bag(UserSortRef(:pro), 1, PNML.NumberEx(UserSortRef(:natural), 1))
    b2 = PNML.Bag(UserSortRef(:pro), 2, PNML.NumberEx(UserSortRef(:natural), 1))
    b3 = PNML.Bag(UserSortRef(:pro), 3, PNML.NumberEx(UserSortRef(:natural), 2))

    a = PNML.Add([b1, b2, b3])
    ex = PNML.toexpr(a, varsub, ddict)
    val = eval(ex)
    @test val == eval(PNML.toexpr(b1, varsub, ddict)) +
                 eval(PNML.toexpr(b2, varsub, ddict)) +
                 eval(PNML.toexpr(b3, varsub, ddict))
end
println()

@testset "multiset and $pntd" begin
    b1 = PNML.BooleanEx(PNML.BooleanConstant(true, ddict))
    b2 = PNML.BooleanEx(PNML.BooleanConstant(false, ddict))
    b3 = PNML.BooleanEx(PNML.BooleanConstant(true, ddict))
    b4 = PNML.BooleanEx(PNML.BooleanConstant(false, ddict))

    a = PNML.And([b1, b2, b3, b4])
    ex = PNML.toexpr(a, varsub, ddict)
    val = eval(ex)
    @test val == eval(PNML.toexpr(b1, varsub, ddict)) &
                 eval(PNML.toexpr(b2, varsub, ddict)) &
                 eval(PNML.toexpr(b3, varsub, ddict)) &
                 eval(PNML.toexpr(b3, varsub, ddict))
end
println()

@testset "multiset or $pntd" begin
    b1 = PNML.BooleanEx(PNML.BooleanConstant(true, ddict))
    b2 = PNML.BooleanEx(PNML.BooleanConstant(false, ddict))
    b3 = PNML.BooleanEx(PNML.BooleanConstant(true, ddict))
    b4 = PNML.BooleanEx(PNML.BooleanConstant(false, ddict))

    a = PNML.Or([b1, b2, b3, b4])
    ex = PNML.toexpr(a, varsub, ddict)
    val = eval(ex)
    @test val == eval(PNML.toexpr(b1, varsub, ddict)) |
                 eval(PNML.toexpr(b2, varsub, ddict)) |
                 eval(PNML.toexpr(b3, varsub, ddict)) |
                 eval(PNML.toexpr(b3, varsub, ddict))
end
println()

@testset "boolean not $pntd" begin
    b1 = PNML.BooleanEx(PNML.BooleanConstant(true, ddict))
    b2 = PNML.BooleanEx(PNML.BooleanConstant(false, ddict))

    a = PNML.Not([b1, b2])
    ex = PNML.toexpr(a, varsub, ddict)
    val = eval(ex)
    @test val == false
end

# And, Or
