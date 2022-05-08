header("LABELS")
@testset "labels" begin
    # Exersize the :labels of a PnmlDict

    d = PNML.PnmlDict(:labels => PNML.PnmlLabel[])
    reg = PNML.IDRegistry()
    for i in 1:4
        x = i<3 ? 1 : 2
        node = root(EzXML.parsexml("<test$x> $i </test$x>"))
        n = PNML.add_label!(d, node, PnmlCore(); reg)
        @test length(PNML.labels(d)) == i
        @test d[:labels] == n # Returned value is the vector
        @test PNML.labels(d) == n # Returned value is the vector
    end
    printnode(d)
    
    @test PNML.labels(d) isa Vector{PNML.PnmlLabel}
    @test length(d[:labels]) == 4
    foreach(PNML.labels(d)) do l
        @test tag(l) === :test1 || tag(l) === :test2
        @test xmlnode(l) isa Maybe{EzXML.Node}
    end
    @show typeof(d), collect(keys(d))
    @test PNML.has_label(d, :test1)
    @test !PNML.has_label(d, :bumble)
    @show PNML.get_label(d, :test2)
    @show PNML.get_labels(d, :test1)
end

