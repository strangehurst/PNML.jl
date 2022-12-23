using PNML, EzXML, ..TestUtils, JET
using PNML: Maybe, tag, pid, xmlnode, firstpage, parse_file, parse_name,
     PnmlModel, PnmlNet, Page, Place, Transition, Arc, Declaration,
     nets, pages, arcs, places, transitions,
     allchildren, firstchild, value
using .PnmlIDRegistrys

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
      </arc>
    </page>
  </net>
</pnml>
"""
pnmldoc = PNML.xmlroot(str) # shared by testsets

@testset "parse tree" begin
    @test EzXML.nodename(pnmldoc) == "pnml"
    @test EzXML.namespace(pnmldoc) == "http://www.pnml.org/version-2009/grammar/pnml"

    reg = IDRegistry()
    # Manually decend tree parsing leaf-enough elements because this is a test!
    foreach(allchildren("net", pnmldoc)) do net
        @test nodename(net) == "net"

        nn = parse_name(firstchild("name", net), PnmlCore(); reg)
        @test isa(nn, PNML.Name)
        @test nn.text == "P/T Net with one place"
        @test nn.graphics === nothing
        @test nn.tools === nothing || isempty(nn.tools)

        nd = allchildren("declaration", net)
        @test_call allchildren("declaration", net)
        @test isempty(nd)
        @test isempty(parse_node.(nd; reg))

        nt = allchildren("toolspecific", net)
        @test isempty(nt)
        @test isempty(parse_node.(nt; reg))

        pages = allchildren("page", net)
        @test !isempty(pages)

        foreach(pages) do page
            @test nodename(page) == "page"

            @test !isempty(allchildren("place", page))
            foreach(allchildren("place", page)) do p
                @test nodename(p) == "place"
                i = parse_node(firstchild("initialMarking", p); reg)
                @test_call firstchild("initialMarking", p)
                @test typeof(i) <: PNML.Marking
                @test typeof(value(i)) <: Union{Int,Float64}
                @test value(i) >= 0
                #@test xmlnode(i) isa Maybe{EzXML.Node}
            end

            @test !isempty(allchildren("transition", page))
            foreach(allchildren("transition", page)) do t
                @test nodename(t) == "transition"
                cond = firstchild("condition", t)
                @test cond === nothing
            end

            @test !isempty(allchildren("arc", page))
            foreach(allchildren("arc", page)) do a
                @test nodename(a) == "arc"
                ins = firstchild("inscription", a)
                if ins !== nothing
                    i = parse_node(ins; reg)
                    @test typeof(i) <: PNML.Inscription
                    @test typeof(value(i)) <: Union{Int,Float64}
                    @test value(i) > 0
                    #@test xmlnode(i) isa Maybe{EzXML.Node}
                end
            end
        end
    end
end

@testset "parse node level" begin
    # Do a full parse and maybe print the generated data structure.
    reg = IDRegistry()
    pnml_ir = parse_pnml(pnmldoc; reg)
    @test typeof(pnml_ir) <: PnmlModel

    foreach(nets(pnml_ir)) do net
        @test net isa PnmlNet
        @test net.id isa Symbol

        foreach(net.pages) do page
            @test page isa Page
            @test pid(page) isa Symbol
            foreach(page.places) do place
                @test place isa Place
                @test pid(place) isa Symbol
            end
            foreach(page.transitions) do transition
                @test transition isa Transition
                @test pid(transition) isa Symbol
            end
            foreach(page.arcs) do arc
                @test arc isa Arc
                @test pid(arc) isa Symbol
            end
            foreach(PNML.declarations(page)) do decl
                @test decl isa Declaration
                @test decl[:text] !== nothing || decl[:structure] !== nothing
            end
        end

        foreach(PNML.declarations(net)) do decl
            @test decl isa Declaration
            @test decl[:text] !== nothing || decl[:structure] !== nothing
        end
    end
end

@testset "AirplaneLD pnml file" begin
    pnml_dir = joinpath(@__DIR__, "data")
    testfile = joinpath(pnml_dir, "AirplaneLD-col-0010.pnml")

    @test_call  parse_file(testfile)

    model = parse_file(testfile)

    @test model isa PnmlModel
    @test_call nets(model)

    netvec = nets(model)

    @test netvec isa Vector{Any}
    @test length(netvec) == 1

    net = first(netvec)

    @test net isa PnmlNet
    @test net isa PnmlNet{<:PnmlType}
    @test pages(net) isa Vector{<:Page}
    @test length(pages(net)) == 1
    @test firstpage(net) isa Page
    @test !isempty(arcs(firstpage(net)))
    @test !isempty(places(firstpage(net)))
    # 3 ways to do the same thing
    @test !isempty(transitions(firstpage(net)))
    @test !isempty(transitions(first(pages(net))))
    @test !isempty(transitions(pages(net)[1]))
end
