@testset "tag $t" for t in keys(PNML.tagmap)
    @test haskey(PNML.tagmap,t)
    @test !isempty(methods(PNML.tagmap[t], (EzXML.Node,)))
end

@testset "labels" begin
    header("LABELS")
    # Exersize the :labels of a PnmlDict

    @testset "tokencolors" begin
        node = xml"""
         <tokencolors>
            <tokencolor>
                <color>red</color>
                <rgbcolor>
                    <r>246</r>
                    <g>5</g>
                    <b>5</b>
                </rgbcolor>
            </tokencolor>
        </tokencolors>
        """
    d = PNML.PnmlDict(:labels=>PnmlDict[])
    n = PNML.add_label!(d, parse_node(node); reg=PNML.IDRegistry())
    printnode(d)
            
    @test d[:labels] == n # Returned value is the vector
    @test labels(d) isa PnmlDict
    @test length(d[:labels]) == 1
    foreach(d[:labels]) do l
        @test tag(l) == :tokencolors
        @test xmlnode(l) isa Maybe{EzXML.Node}
    end
end

