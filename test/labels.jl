@testset "tag $t" for t in keys(PNML.tagmap)
    @test haskey(PNML.tagmap,t)
    @test !isempty(methods(PNML.tagmap[t], (EzXML.Node,)))
end

@testset "labels" begin
    header("LABELS")
    # Exersize the :labels of a PnmlDict
    labels = PnmlDict[]

    @testset "tokencolors" begin
        str1 = """
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
        @testset for s in [str1] #, str2, str3] 
            d = PNML.PnmlDict(:labels=>labels)
            n = PNML.add_label!(d, root(EzXML.parsexml(s)); reg=PNML.IDRegistry())
            printnode(d)
            
            @test d[:labels] == n
            @test length(d[:labels]) == 1
            foreach(d[:labels]) do l
                @test tag(l) == :tokencolors
                @test xmlnode(l) isa Maybe{EzXML.Node}
            end
        end
    end
end

