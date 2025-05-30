using PNML, ..TestUtils, JET, NamedTupleTools, AbstractTrees
using EzXML: EzXML
using XMLDict: XMLDict

# See PnmlExpr
_op() = (; args=(PNML.Bag(UserSort(:pro), 1, PNML.NumberEx(UserSort(:natural), 1)),
PNML.Bag(UserSort(:pro), 2, PNML.NumberEx(UserSort(:natural), 1)), ))

@testset "multiset add $pntd" for pntd in PnmlTypeDefs.all_nettypes(ishighlevel)
    #
    #println()
    @with PNML.idregistry => PnmlIDRegistry() begin
        ddict = PNML.decldict(PNML.idregistry[])
        varsub = NamedTuple()
        #@show PNML.pnmlmultiset(UserSort(:dot), DotConstant(ddict))
        #Add
        b1 = PNML.Bag(UserSort(:pro, ddict), 1, PNML.NumberEx(UserSort(:natural, ddict), 1))
        b2 = PNML.Bag(UserSort(:pro, ddict), 2, PNML.NumberEx(UserSort(:natural, ddict), 1))
        #@show b1 b2

        b1x = PNML.toexpr(b1, varsub, ddict)
        b2x = PNML.toexpr(b2, varsub, ddict)
        #@show b1x b2x
        a = PNML.Add([b1, b2])
        ex = PNML.toexpr(a, varsub, ddict)
        val = eval(ex)
        @test val == eval(PNML.toexpr(b1, varsub, ddict)) + eval(PNML.toexpr(b2, varsub, ddict))

        # op = _op()::NamedTuple
        # #; args=(b1,b2))
        # #@show toexpr.(op.args, Ref(subdict))
        # ex2 =  Expr(:call, sum, (eval ∘ toexpr).(op.args, Ref(varsub))) # constructs a new PnmlMultiset
        # @show ex2 eval(ex2)
    end
end
