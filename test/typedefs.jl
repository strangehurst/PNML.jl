using PNML, EzXML, ..TestUtils, JET
using PNML: XMLNode, pnmltype

@testset "pntd_symbol" begin
    @test_opt pntd_symbol("foo")
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
    @test pnmltype(PT_HLPNG()) === PT_HLPNG()
    @test pnmltype(SymmetricNet()) === SymmetricNet()

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
    @test pnmltype("nonstandard" ) === PnmlCoreNet()
    @test pnmltype("continuous"  ) === ContinuousNet()

    @test pnmltype(:pnmlcore)   === PnmlCoreNet()
    @test pnmltype(:hlcore)     === HLCoreNet()
    @test pnmltype(:ptnet)      === PTNet()
    @test pnmltype(:hlnet)      === HLPNG()
    @test pnmltype(:pt_hlpng)   === PT_HLPNG()
    @test pnmltype(:symmetric)  === SymmetricNet()
    @test pnmltype(:continuous) === ContinuousNet()
end

@testset "pnml traits $pntd" for pntd in all_nettypes()
    @test isdiscrete(pntd) isa Bool
    @test iscontinuous(pntd) isa Bool
    @test ishighlevel(pntd) isa Bool
end
