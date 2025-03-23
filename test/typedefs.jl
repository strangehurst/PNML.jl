using PNML, ..TestUtils, JET

@testset "pntd_symbol" begin
    @test_opt PnmlTypeDefs.pntd_symbol("foo")
    @test_call PnmlTypeDefs.pntd_symbol("foo")

    @test PnmlTypeDefs.pntd_symbol("foo") === :pnmlcore

    @test PnmlTypeDefs.pntd_symbol("http://www.pnml.org/version-2009/grammar/ptnet") === :ptnet
    @test PnmlTypeDefs.pntd_symbol("http://www.pnml.org/version-2009/grammar/highlevelnet") === :hlnet
    @test PnmlTypeDefs.pntd_symbol("http://www.pnml.org/version-2009/grammar/pnmlcoremodel") === :pnmlcore
    @test PnmlTypeDefs.pntd_symbol("http://www.pnml.org/version-2009/grammar/pnmlcore") === :pnmlcore
    @test PnmlTypeDefs.pntd_symbol("http://www.pnml.org/version-2009/grammar/pt-hlpng") === :pt_hlpng
    @test PnmlTypeDefs.pntd_symbol("http://www.pnml.org/version-2009/grammar/symmetricnet") === :symmetric
    @test PnmlTypeDefs.pntd_symbol("pnmlcore"  ) === :pnmlcore
    @test PnmlTypeDefs.pntd_symbol("ptnet"     ) === :ptnet
    @test PnmlTypeDefs.pntd_symbol("hlnet"     ) === :hlnet
    @test PnmlTypeDefs.pntd_symbol("hlcore"    ) === :hlcore
    @test PnmlTypeDefs.pntd_symbol("pt-hlpng"  ) === :pt_hlpng
    @test PnmlTypeDefs.pntd_symbol("pt_hlpng"  ) === :pt_hlpng
    @test PnmlTypeDefs.pntd_symbol("symmetric" ) === :symmetric
    @test PnmlTypeDefs.pntd_symbol("symmetricnet") === :symmetric

    @test PnmlTypeDefs.pntd_symbol("nonstandard" ) === :pnmlcore
    @test PnmlTypeDefs.pntd_symbol("open"        ) === :pnmlcore
    @test PnmlTypeDefs.pntd_symbol("continuous"  ) === :continuous
end

@testset "pnmltype" begin
    #@test_call PNML.PnmlTypeDefs.default_pntd_map()
    @test_call PnmlTypeDefs.pnmltype(PnmlCoreNet())
    @test_call PnmlTypeDefs.pnmltype("pnmlcore")
    @test_call PnmlTypeDefs.pnmltype(:pnmlcore)

    @test_throws MethodError PnmlTypeDefs.pnmltype(Nothing())
    @test_throws MethodError PnmlTypeDefs.pnmltype(Any[])
    @test_throws DomainError PnmlTypeDefs.pnmltype(:garbage)

    @test PnmlTypeDefs.pnmltype(PnmlCoreNet()) === PnmlCoreNet()
    @test PnmlTypeDefs.pnmltype(ContinuousNet()) === ContinuousNet()
    @test PnmlTypeDefs.pnmltype(PTNet()) === PTNet()
    @test PnmlTypeDefs.pnmltype(HLCoreNet()) === HLCoreNet()
    @test PnmlTypeDefs.pnmltype(HLPNG()) === HLPNG()
    @test PnmlTypeDefs.pnmltype(PT_HLPNG()) === PT_HLPNG()
    @test PnmlTypeDefs.pnmltype(SymmetricNet()) === SymmetricNet()

    @test PnmlTypeDefs.pnmltype("foo") === PnmlCoreNet()

    @test PnmlTypeDefs.pnmltype("http://www.pnml.org/version-2009/grammar/ptnet") === PTNet()
    @test PnmlTypeDefs.pnmltype("http://www.pnml.org/version-2009/grammar/highlevelnet") === HLPNG()
    @test PnmlTypeDefs.pnmltype("http://www.pnml.org/version-2009/grammar/pnmlcoremodel") === PnmlCoreNet()
    @test PnmlTypeDefs.pnmltype("http://www.pnml.org/version-2009/grammar/pnmlcore") === PnmlCoreNet()
    @test PnmlTypeDefs.pnmltype("http://www.pnml.org/version-2009/grammar/pt-hlpng") === PT_HLPNG()
    @test PnmlTypeDefs.pnmltype("http://www.pnml.org/version-2009/grammar/symmetricnet") === SymmetricNet()
    @test PnmlTypeDefs.pnmltype("pnmlcore"  ) === PnmlCoreNet()
    @test PnmlTypeDefs.pnmltype("ptnet"     ) === PTNet()
    @test PnmlTypeDefs.pnmltype("hlnet"     ) === HLPNG()
    @test PnmlTypeDefs.pnmltype("hlcore"    ) === HLCoreNet()
    @test PnmlTypeDefs.pnmltype("pt-hlpng"  ) === PT_HLPNG()
    @test PnmlTypeDefs.pnmltype("pt_hlpng"  ) === PT_HLPNG()
    @test PnmlTypeDefs.pnmltype("symmetric" ) === SymmetricNet()
    @test PnmlTypeDefs.pnmltype("symmetricnet") === SymmetricNet()
    @test PnmlTypeDefs.pnmltype("nonstandard" ) === PnmlCoreNet()
    @test PnmlTypeDefs.pnmltype("continuous"  ) === ContinuousNet()

    @test PnmlTypeDefs.pnmltype(:pnmlcore)   === PnmlCoreNet() # most basic
    @test PnmlTypeDefs.pnmltype(:ptnet)      === PTNet() # collective token identity meta-model
    @test PnmlTypeDefs.pnmltype(:hlcore)     === HLCoreNet() # individual token identity meta-model
    @test PnmlTypeDefs.pnmltype(:pt_hlpng)   === PT_HLPNG() # really-restricted meta-model
    @test PnmlTypeDefs.pnmltype(:symmetric)  === SymmetricNet() # restricted meta-model
    @test PnmlTypeDefs.pnmltype(:hlnet)      === HLPNG() # full-fat meta-model
    @test PnmlTypeDefs.pnmltype(:continuous) === ContinuousNet() # not in standard, collective identity
end

@testset "pnml traits $pntd" for pntd in PnmlTypeDefs.all_nettypes()
    @test PnmlTypeDefs.isdiscrete(pntd) isa Bool
    @test iscontinuous(pntd) isa Bool
    @test ishighlevel(pntd) isa Bool
end
