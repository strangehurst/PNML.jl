

    
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

    reg = PNML.IDRegistry()
    # Manually decend tree parsing leaf-enough elements because this is a test!
    foreach(PNML.allchildren("net", pnml)) do net
        @test nodename(net) == "net"
        
        nn = parse_name(PNML.firstchild("name", net); reg)
        @test nn.tag == :name
        @test nn.value == "P/T Net with one place"
        @test nn.graphics === nothing
        @test haskey(nn,:tools)
        @test nn[:tools] === nothing || isempty(nn[:tools])

        nd = PNML.allchildren("declaration", net)
        @test isempty(nd)
        @test isempty(parse_node.(nd; reg)) # Empty elements are leaf-enough.
        
        nt = PNML.allchildren("toolspecific", net)
        @test isempty(nt)
        @test isempty(parse_node.(nt; reg))
       
        pages = PNML.allchildren("page", net)
        @test !isempty(pages)
        
        foreach(pages) do page
            @test nodename(page) == "page"
            
            @test !isempty(PNML.allchildren("place", page))
            foreach(PNML.allchildren("place", page)) do p
                @test nodename(p) == "place"
                i = parse_node(PNML.firstchild("initialMarking", p); reg)
                @test i[:tag] == :initialMarking
                @test i[:value] !== nothing
                @test i[:value] >= 0
                @test isnothing(i[:xml]) || i[:xml] isa EzXML.Node
            end
            
            @test !isempty(PNML.allchildren("transition", page))
            foreach(PNML.allchildren("transition", page)) do t
                @test nodename(t) == "transition"
                i = parse_node(PNML.firstchild("condition", t); reg)
                @test i === nothing
            end
            
            @test !isempty(PNML.allchildren("arc", page))            
            foreach(PNML.allchildren("arc", page)) do a
                @test nodename(a) == "arc"
                i = parse_node(PNML.firstchild("inscription", a); reg)
                @test i[:tag] == :inscription
                @test i[:value] !== nothing
                @test i[:value] > 0
                @test isnothing(i[:xml]) || i[:xml] isa EzXML.Node
            end
        end
    end
    PNML.reset_registry!(reg)
end

@testset "parse node level" begin

    # Do a full parse and maybe print the generated data structure.
    reg = PNML.IDRegistry()
    pnml_ir = parse_pnml(root(doc); reg)
    @test pnml_ir isa PNML.PnmlDict # not PNML.Document
    #printnode(e)

    if SHOW_SUMMARYSIZE && PRINT_PNML
        @show Base.summarysize(pnml_ir)        
        showsize.(Ref(pnml_ir), keys(pnml_ir))
        foreach(pnml_ir[:nets]) do net
            showsize.(Ref(net), keys(net))
            foreach(net[:pages]) do page
                showsize.(Ref(page), keys(page))
                for k in [:graphics, :tools, :labels, :places, :trans,
                          :arcs, :declarations, :refT, :refP]
                    if !isnothing(page[k])
                        showsize.(Ref(page[k]), keys(page[k]))
                        foreach(page[k]) do k2
                            showsize.(Ref(k2), keys(k2))
                        end
                    end
                end
            end
        end
    end
    println()
                              
    foreach(pnml_ir[:nets]) do net
        @test net isa PNML.PnmlDict
        @test net[:tag] == :net
        @test net[:id] isa Symbol
        
        foreach(net[:pages]) do page
            @test page isa PNML.PnmlDict
            @test page[:tag] == :page
            @test page[:id] isa Symbol
            foreach(page[:places]) do place
                @test place isa PNML.PnmlDict
                @test place[:tag] == :place
                @test place[:id] isa Symbol
            end
            foreach(page[:trans]) do transition
                @test transition isa PNML.PnmlDict
                @test transition[:tag] == :transition
                @test transition[:id] isa Symbol
            end
            foreach(page[:arcs]) do arc
                @test arc isa PNML.PnmlDict
                @test arc[:tag] == :arc
                @test arc[:id] isa Symbol
            end
            foreach(page[:declarations]) do decl
                @test decl isa PNML.PnmlDict
                @test decl[:tag] = :declaration
                @test decl[:text] !== nothing || decl[:structure] !== nothing
            end
        end

        foreach(net[:declarations]) do decl
            @test decl isa PNML.PnmlDict
            @test decl[:tag] = :declaration
            @test decl[:text] !== nothing || decl[:structure] !== nothing
        end 
    end
    
    PNML.reset_registry!(reg)
    println()
end
