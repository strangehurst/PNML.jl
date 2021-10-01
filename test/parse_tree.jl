

    
str = """
<?xml version="1.0"?><!-- https://github.com/daemontus/pnml-parser -->
<pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
  <net id="small-net" type="http://www.pnml.org/version-2009/grammar/ptnet">
    <name> <text>P/T Net with one place</text> </name>
    <page id="page0">
      <place id="place1">
	<name> <text>Some place</text> </name>
	<initialMarking> <text>100</text> </initialMarking>
      </place>
      <transition id="transition1">
        <name> <text>Some transition </text> </name>
      </transition>
      <arc source="transition1" target="place1" id="arc1">
        <inscription> <text>12 </text> </inscription>
      </arc>
      <arc source="place1" target="transition1" id="arc2">
        <inscription> <text> 13 </text> </inscription>
      </arc>
    </page>
  </net>
</pnml>
    """

doc = EzXML.parsexml(str)
if PRINT_PNML
    EzXML.prettyprint(doc);
    println()
end

@testset "parse1" begin
    pnml = root(doc)
    @test EzXML.nodename(pnml) == "pnml"
    @test EzXML.namespace(pnml) == "http://www.pnml.org/version-2009/grammar/pnml"
    
    # Manually decend tree parsing leaf-enough elements because this is a test!
    foreach(PNML.allchildren("net", pnml)) do net
        @test nodename(net) == "net"
        
        nn = parse_name(PNML.firstchild("name", net))
        @test nn.tag == :name
        @test nn.value == "P/T Net with one place"
        @test nn.graphics === nothing
        @test haskey(nn,:tools)
        @test nn[:tools] === nothing || isempty(nn[:tools])

        nd = PNML.allchildren("declaration", net)
        @test isempty(nd)
        @test isempty(parse_node.(nd)) # Empty elements are leaf-enough.
        
        nt = PNML.allchildren("toolspecific", net)
        @test isempty(nt)
        @test isempty(parse_node.(nt))
        
        pages = PNML.allchildren("page", net)
        @test !isempty(pages)
        
        foreach(pages) do page
            @test nodename(page) == "page"
            
            @test !isempty(PNML.allchildren("place", page))
            foreach(PNML.allchildren("place", page)) do p
                @test nodename(p) == "place"
                i = parse_node(PNML.firstchild("initialMarking", p))
                @test i[:tag] == :initialMarking
                @test i[:value] !== nothing
                @test i[:value] >= 0
                @test !haskey(i,:xml) || i[:xml] isa EzXML.Node
            end
            
            @test !isempty(PNML.allchildren("transition", page))
            foreach(PNML.allchildren("transition", page)) do t
                @test nodename(t) == "transition"
                i = parse_node(PNML.firstchild("condition", t))
                @test i == nothing
            end
            
            @test !isempty(PNML.allchildren("arc", page))            
            foreach(PNML.allchildren("arc", page)) do a
                @test nodename(a) == "arc"
                i = parse_node(PNML.firstchild("inscription", a))
                @test i[:tag] == :inscription
                @test i[:value] !== nothing
                @test i[:value] > 0
                @test !haskey(i,:xml) || i[:xml] isa EzXML.Node
            end
        end
    end
end

@testset "parse node level" begin

    # Do a full parse and maybe print the generated data structure.
    e = parse_doc(doc)
    printnode(e)

    # Access the returned data structure.
    if SHOW_SUMMARYSIZE && PRINT_PNML
        @show Base.summarysize(e)
    end
    foreach(e[:nets]) do net
        @testset "net keys" for k in [:id, :name, :tag, :xml, 
                                      :graphics, :tools, :labels,
                                      :pages, :declarations]
            haskey(net, k) && showsize(net,k)
        end
        @test net[:tag] == :net
        @test net[:id] isa Symbol
        #@test length(net[:id]) > 0

        foreach(net[:declarations]) do decl
            @testset "declaration keys" for k in [:id, :name, :tag, :xml,
                                                  :graphics, :tools, :labels,
                                                  :text, :structure]
                haskey(decl, k) && showsize(decl,k)
            end
            @test decl[:tag] = :declaration
            @test decl[:test] !== nothing || decl[:structure] !== nothing
        end
        
        foreach(net[:pages]) do page
            @testset "page keys" for k in [:id, :name, :tag, :xml,
                                           :graphics, :tools, :labels,
                                           :places, :trans, :arcs,
                                           :declarations, :refT, :refP]
                haskey(page, k) && showsize(page,k)
            end
            @test page[:tag] == :page
            @test page[:id] isa Symbol
            #@test length(page[:id]) > 0
            
            foreach(page[:places]) do place
                @testset "place keys" for k in [:id, :name, :tag, :xml,
                                                :graphics, :tools, :labels,
                                                :marking, :type]
                    haskey(place,k) && showsize(place,k)
                end
                @test place[:tag] == :place
                @test place[:id] isa Symbol
                #@test length(place[:id]) > 0
            end
 
            foreach(page[:trans]) do transition
                @testset "place keys" for k in [:id, :name, :tag, :xml,
                                                :graphics, :tools, :labels,
                                                :condition]
                    haskey(transition,k) && showsize(transition,k)
                end
                @test transition[:tag] == :transition
                @test transition[:id] isa Symbol
                #@test length(transition[:id]) > 0
           end

            foreach(page[:arcs]) do arc
                @testset "place keys" for k in [:id, :name, :tag, :xml,
                                                :graphics, :tools, :labels,
                                                :inscription]
                    haskey(arc,k) && showsize(arc,k)
                end
                @test arc[:tag] == :arc
                @test arc[:id] isa Symbol
                #@test length(arc[:id]) > 0
            end
        end
    end
    println()
end
