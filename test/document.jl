
@testset "net type" begin
    # pnml with multiple nets.    
    str = """
    <?xml version="1.0"?><!-- https://github.com/daemontus/pnml-parser -->
    <pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
      <net id="net1" type="http://www.pnml.org/version-2009/grammar/ptnet"> <page id="page1"/> </net>
      <net id="net2" type="pnmlcore"> <page id="page2"/> </net>
      <net id="net3" type="ptnet"> <page id="page3"/> </net>
      <net id="net4" type="hlcore"> <page id="page4"/> </net>
      <net id="net5" type="pt_hlpng"> <page id="page5"/> </net>
    </pnml>
        """ 

    reg = PNML.IDRegistry()
    #@test !PNML.isregistered(reg, :pnml)

    doc = PNML.Document(str, reg)
    #printnode(doc.nets);println()
    @show doc
    @show reg
    
    v1 = PNML.find_nets(doc, :ptnet)
    printnode(v1, label="v1")
    foreach(v1) do net
        @test net[:type] === :ptnet
    end    
    v2 = PNML.find_nets(doc, "ptnet")
    printnode(v2, label="v2")
    foreach(v2) do net
        @test net[:type] === :ptnet
    end    
    
    @test v1 == v2
    @test length(v1) == 2
    
    v3 = PNML.find_nets(doc, :pnmlcore)
    printnode(v3, label="v3")
    foreach(v3) do net
        @test net[:type] === :pnmlcore
    end    
    
    @test !isempty(v3)
    @test v3 != v1
    
    @testset for t in [:ptnet, :pnmlcore, :hlcore, :pt_hlpng, :hlnet, :symmetric, :stochastic, :timednet]
        foreach(PNML.find_nets(doc, t)) do net
            @test net[:type] === t
        end
    end
    #PNML.reset_registry!(reg)
end

