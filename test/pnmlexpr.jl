using PNML, ..TestUtils, JET, NamedTupleTools, AbstractTrees
using EzXML: EzXML
using XMLDict: XMLDict

# See PnmlExpr
_op() = (; args=(Bag(UserSort(:pro), 1, NumberEx(UserSort(:natural), 1)),
                Bag(UserSort(:pro), 2, NumberEx(UserSort(:natural), 1)), ))
@testset "add $pntd" for pntd in all_nettypes(ishighlevel)
    #
    println()
    @with PNML.idregistry => registry() PNML.DECLDICT => PNML.DeclDict() begin
        varsub = NamedTuple()
        #@show PNML.pnmlmultiset(UserSort(:dot), DotConstant())
        #Add
        b1 = Bag(UserSort(:pro), 1, NumberEx(UserSort(:natural), 1))
        b2 = Bag(UserSort(:pro), 2, NumberEx(UserSort(:natural), 1))
        #@show b1 b2
        @show a = Add([b1, b2])
        #@show toexpr(b1, subdict) eval(toexpr(b1, varsub))
        #@show toexpr(b2, subdict) eval(toexpr(b2, varsub))
        @show eval(toexpr(b1, varsub)) + eval(toexpr(b2, varsub))
        @show ex = toexpr(a, varsub)
        @show eval(ex)
        #@test eval(toexpr(term(mark))) isa PNML.PnmlMultiset

        op = _op()::NamedTuple
        #; args=(b1,b2))
        #@show toexpr.(op.args, Ref(subdict))
        ex2 =  Expr(:call, sum, (eval ∘ toexpr).(op.args, Ref(varsub))) # constructs a new PnmlMultiset
        @show ex2 eval(ex2)
    end
end
