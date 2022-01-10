str =
    """
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
header("parse tree")
doc = EzXML.parsexml(str) # shared by testsets

if PRINT_PNML
    EzXML.prettyprint(doc);
    println()
end

@testset "parse nodes" begin
    pnml = root(doc)
    @test EzXML.nodename(pnml) == "pnml"
    @test EzXML.namespace(pnml) == "http://www.pnml.org/version-2009/grammar/pnml"

    reg = PNML.IDRegistry()
    # Manually decend tree parsing leaf-enough elements because this is a test!
    foreach(PNML.allchildren("net", pnml)) do net
        @test nodename(net) == "net"
        
        nn = parse_name(PNML.firstchild("name", net); reg)
        @test isa(nn, PNML.Name)
        @test nn.text == "P/T Net with one place"
        @test nn.graphics === nothing
        @test nn.tools === nothing || isempty(nn.tools)

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
                @test typeof(i) <: PNML.PTMarking
                @test typeof(i.value) <: Number
                @test i.value >= 0
                @test xmlnode(i) isa Maybe{EzXML.Node}
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
                @test typeof(i) <: PNML.PTInscription
                @test typeof(i.value) <: Number
                @test i.value > 0
                @test xmlnode(i) isa Maybe{EzXML.Node}
            end
        end
    end
    PNML.reset_registry!(reg)
end

@testset "parse node level" begin

    # Do a full parse and maybe print the generated data structure.
    reg = PNML.IDRegistry()
    pnml_ir = parse_pnml(root(doc); reg)
    @show typeof(pnml_ir)
    @test typeof(pnml_ir) <: PNML.Pnml
    
    printnode(pnml_ir; label="pnml_ir")
    #=

    This assumes everything has keys.
    
    header("Summary of sizes")
    if SHOW_SUMMARYSIZE && PRINT_PNML
        @show Base.summarysize(pnml_ir)        
        showsize.(Ref(pnml_ir), keys(pnml_ir))
        foreach(pnml_ir[:nets]) do net
            print("net ", pid(net), "\n")
            showsize.(Ref(net), keys(net))
            foreach(net.pages) do page
                print("page ", pid(page), "\n")
                showsize.(Ref(page), keys(page))
                for k in [:graphics, :tools, :labels,
                          :places, :trans, :arcs, :declarations, :refT, :refP]
                    if !isnothing(page[k])
                        print(k, " ", "\n")
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
    =#
    foreach(pnml_ir.nets) do net
        @test net isa PNML.PnmlNet
        @test net.id isa Symbol
        
        foreach(net.pages) do page
            @test page isa PNML.Page
            @test pid(page) isa Symbol
            foreach(page.places) do place
                @test place isa PNML.Place
                @test pid(place) isa Symbol
            end
            foreach(page.transitions) do transition
                @test transition isa PNML.Transition
                @test pid(transition) isa Symbol
            end
            foreach(page.arcs) do arc
                @test arc isa PNML.Arc
                @test pid(arc) isa Symbol
            end
            foreach(page.declarations) do decl
                @test decl isa PNML.Declaration
                @test decl[:text] !== nothing || decl[:structure] !== nothing
            end
        end

        foreach(net.declarations) do decl
            @test decl isa PNML.Declaration
            @test decl[:text] !== nothing || decl[:structure] !== nothing
        end 
    end
    
    PNML.reset_registry!(reg)
end

