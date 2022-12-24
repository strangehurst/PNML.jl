using PNML, EzXML
using JET
using PNML: IDRegistry, XMLNode, pnmltype, tagmap

@testset "tagmap" begin
    # Tags handled differently (no pntd argument) are not in the map.
    @test !haskey(tagmap, "pnml")
    @test !haskey(tagmap, "net")
    # Visit every entry in the map.  All require pntd.
    @testset "tag $t" for t in keys(tagmap)
        @test !isempty(methods(tagmap[t], (XMLNode, PnmlType)))
        @test isempty(methods(tagmap[t], (XMLNode,)))
        @show t, tagmap[t]

        #! Some tags only HighLevel
        highleveltags = ["hlmarking", "hlinitialMarking", "hlinscription",
                        "namedoperator", "declarations", "declaration"]
        if any(==(t), highleveltags)
            @test_call tagmap[t](xmlroot("<$(t)></$(t)>"), HLCoreNet(); reg=IDRegistry() )
        else
            @test_call tagmap[t](xmlroot("<$(t)></$(t)>"), PnmlCoreNet(); reg=IDRegistry() )
        end

    end
    #TODO: Add non-trivial tests.
end

@testset "pntd_symbol" begin
    @test_call pntd_symbol("foo")

    @test pntd_symbol("foo") === :pnmlcore

    @test pntd_symbol("http://www.pnml.org/version-2009/grammar/ptnet") === :ptnet
    @test pntd_symbol("http://www.pnml.org/version-2009/grammar/highlevelnet") === :hlnet
    @test pntd_symbol("http://www.pnml.org/version-2009/grammar/pnmlcoremodel") === :pnmlcore
    @test pntd_symbol("http://www.pnml.org/version-2009/grammar/pnmlcore") === :pnmlcore
    @test pntd_symbol("http://www.pnml.org/version-2009/grammar/pt-hlpng") === :pt_hlpng
    @test pntd_symbol("http://www.pnml.org/version-2009/grammar/symmetricnet") === :symmetric
    @test pntd_symbol("pnmlcore"  ) === :pnmlcore
    @test pntd_symbol("ptnet"     ) === :ptnet
    @test pntd_symbol("hlnet"     ) === :hlnet
    @test pntd_symbol("hlcore"    ) === :hlcore
    @test pntd_symbol("pt-hlpng"  ) === :pt_hlpng
    @test pntd_symbol("pt_hlpng"  ) === :pt_hlpng
    @test pntd_symbol("symmetric" ) === :symmetric
    @test pntd_symbol("symmetricnet") === :symmetric


    @test pntd_symbol("stochastic"  ) === :stochastic
    @test pntd_symbol("timed"       ) === :timednet
    @test pntd_symbol("nonstandard" ) === :pnmlcore
    @test pntd_symbol("open"        ) === :pnmlcore
    @test pntd_symbol("continuous"  ) === :continuous
end

@testset "pnmltype" begin
    #@test_call PNML.PnmlTypeDefs.default_pntd_map()
    @test_call pnmltype(PnmlCoreNet())
    @test_call pnmltype("pnmlcore")
    @test_call pnmltype(:pnmlcore)

    @test_throws MethodError pnmltype(Nothing())
    @test_throws MethodError pnmltype(Any[])
    @test_throws DomainError pnmltype(:garbage)

    @test pnmltype(PnmlCoreNet()) === PnmlCoreNet()
    @test pnmltype(ContinuousNet()) === ContinuousNet()
    @test pnmltype(PTNet()) === PTNet()
    @test pnmltype(HLCoreNet()) === HLCoreNet()
    @test pnmltype(HLPNG()) === HLPNG()
    @test pnmltype(OpenNet()) === OpenNet()
    @test pnmltype(PT_HLPNG()) === PT_HLPNG()
    @test pnmltype(StochasticNet()) === StochasticNet()
    @test pnmltype(SymmetricNet()) === SymmetricNet()
    @test pnmltype(TimedNet()) === TimedNet()

    @test pnmltype("foo") === PnmlCoreNet()

    @test pnmltype("http://www.pnml.org/version-2009/grammar/ptnet") === PTNet()
    @test pnmltype("http://www.pnml.org/version-2009/grammar/highlevelnet") === HLPNG()
    @test pnmltype("http://www.pnml.org/version-2009/grammar/pnmlcoremodel") === PnmlCoreNet()
    @test pnmltype("http://www.pnml.org/version-2009/grammar/pnmlcore") === PnmlCoreNet()
    @test pnmltype("http://www.pnml.org/version-2009/grammar/pt-hlpng") === PT_HLPNG()
    @test pnmltype("http://www.pnml.org/version-2009/grammar/symmetricnet") === SymmetricNet()
    @test pnmltype("pnmlcore"  ) === PnmlCoreNet()
    @test pnmltype("ptnet"     ) === PTNet()
    @test pnmltype("hlnet"     ) === HLPNG()
    @test pnmltype("hlcore"    ) === HLCoreNet()
    @test pnmltype("pt-hlpng"  ) === PT_HLPNG()
    @test pnmltype("pt_hlpng"  ) === PT_HLPNG()
    @test pnmltype("symmetric" ) === SymmetricNet()
    @test pnmltype("symmetricnet") === SymmetricNet()
    @test pnmltype("stochastic"  ) === StochasticNet()
    @test pnmltype("timed"       ) === TimedNet()
    @test pnmltype("nonstandard" ) === PnmlCoreNet()
    @test pnmltype("open"        ) === PnmlCoreNet()
    @test pnmltype("continuous"  ) === ContinuousNet()

    @test pnmltype(:pnmlcore)   === PnmlCoreNet()
    @test pnmltype(:hlcore)     === HLCoreNet()
    @test pnmltype(:ptnet)      === PTNet()
    @test pnmltype(:hlnet)      === HLPNG()
    @test pnmltype(:pt_hlpng)   === PT_HLPNG()
    @test pnmltype(:symmetric)  === SymmetricNet()
    @test pnmltype(:stochastic) === StochasticNet()
    @test pnmltype(:timednet)   === TimedNet()
    @test pnmltype(:continuous) === ContinuousNet()
end
