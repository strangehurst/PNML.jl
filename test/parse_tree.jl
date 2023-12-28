using PNML, EzXML, ..TestUtils, JET, OrderedCollections
using PNML: Maybe,
    tag, pid, firstpage, length,
    parse_file, parse_name, parse_initialMarking, parse_inscription,
    parse_declaration, parse_transition,  parse_toolspecific,
    PnmlModel, PnmlNet, Page, Place, Transition, Arc, Declaration,
    nets, pages, arcs, place, places, transitions, has_place,
    allchildren, firstchild, value, allpages

const str = """
<?xml version="1.0"?>
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
const pnmldoc = PNML.xmlroot(str) # shared by testsets

@testset "parse tree" begin
    @test EzXML.nodename(pnmldoc) == "pnml"
    @test EzXML.namespace(pnmldoc) == "http://www.pnml.org/version-2009/grammar/pnml"

    reg = registry()
    # Manually decend tree parsing leaf-enough elements because this is a test!
    for net in allchildren("net", pnmldoc)
        @test EzXML.nodename(net) == "net"

        nn = parse_name(firstchild("name", net), PnmlCoreNet(), reg)
        @test isa(nn, PNML.Name)
        @test PNML.text(nn) == "P/T Net with one place"

        nd = allchildren("declaration", net)
        @test isempty(nd)
        ndx = parse_declaration.(nd, Ref(reg)) # test of broadcast over `nothing`
        @test isempty(ndx)
        @test_call target_modules=target_modules allchildren("declaration", net)

        nt = allchildren("toolspecific", net)
        @test isempty(nt)
        @test isempty(parse_toolspecific.(nt, Ref(reg)))

        pages = allchildren("page", net)
        @test !isempty(pages)

        for page in pages
            @test EzXML.nodename(page) == "page"

            @test !isempty(allchildren("place", page))
            for p in allchildren("place", page)
                @test EzXML.nodename(p) == "place"
                fc = firstchild("initialMarking", p)
                i = parse_initialMarking(fc, PnmlCoreNet(), reg)
                #@test_opt function_filter=pff firstchild("initialMarking", p)
                @test_call target_modules=target_modules firstchild("initialMarking", p)
                @test typeof(i) <: PNML.Marking
                @test typeof(value(i)) <: Union{Int,Float64}
                @test value(i) >= 0
            end

            @test !isempty(allchildren("transition", page))
            for t in allchildren("transition", page)
                @test EzXML.nodename(t) == "transition"
                cond = firstchild("condition", t)
                @test cond === nothing
            end

            @test !isempty(allchildren("arc", page))
            for a in allchildren("arc", page)
                @test EzXML.nodename(a) == "arc"
                ins = firstchild("inscription", a)
                if ins !== nothing
                    i = parse_inscription(ins, PnmlCoreNet(), reg)
                    @test typeof(i) <: PNML.Inscription
                    @test typeof(value(i)) <: Union{Int,Float64}
                    @test value(i) > 0
                end
            end
        end
    end
end

@testset "parse node level" begin
    # Do a full parse and maybe print the generated data structure.
    pnml_ir = parse_pnml(pnmldoc, registry())
    @show @test pnml_ir isa PnmlModel

    for net in nets(pnml_ir)
        @test net isa PnmlNet
        @test pid(net) isa Symbol

        for page in pages(net)
            @test page isa Page
            @test pid(page) isa Symbol
            for p in places(page)
                @test p isa Place
                placeid = pid(p)
                @test placeid isa Symbol
                @test has_place(page, placeid)
                @test pid(place(page, placeid)) === placeid
            end
            for transition in transitions(page)
                @test transition isa Transition
                @test pid(transition) isa Symbol
            end
            for arc in arcs(page)
                @test arc isa Arc
                @test pid(arc) isa Symbol
            end
            for decl in PNML.declarations(page)
                @test decl isa Declaration
                @test decl[:text] !== nothing || decl[:structure] !== nothing
            end
        end

        for decl in PNML.declarations(net)
            @test decl isa Declaration
            @test decl[:text] !== nothing || decl[:structure] !== nothing
        end
    end
end

# Read a SymmetricNet from www.pnml.com examples or MCC
@testset "AirplaneLD pnml file" begin
    pnml_dir = joinpath(@__DIR__, "data")
    @show testfile = joinpath(pnml_dir, "AirplaneLD-col-0010.pnml")

    model = parse_file(testfile)
    @test model isa PnmlModel

    netvec = nets(model)
    @test netvec isa Tuple{Vararg{PnmlNet{<:PnmlType}}}
    @test length(netvec) == 1

    net = first(netvec)
    @test net isa PnmlNet{<:SymmetricNet}

    @test pages(net) isa Base.Iterators.Filter
    @test only(allpages(net)) == only(pages(net))
    #todo compare pages(net) == allpages(net)
    @test firstpage(net) isa Page
    @test !isempty(arcs(firstpage(net)))
    @test !isempty(places(firstpage(net)))
    # 2 ways to do the same thing
    @test !isempty(transitions(firstpage(net)))
    @test !isempty(transitions(first(pages(net))))
    @test transitions(firstpage(net)) == transitions(first(pages(net)))

    @test_call target_modules=target_modules parse_file(testfile)
    @test_call nets(model)
end

# Read a file
@testset "test1.pnml file" begin
    model = parse_file(joinpath(@__DIR__, "../snoopy", "test1.pnml"))
    @test model isa PnmlModel
    x = repr(model)
    @test startswith(x, "PnmlModel")
    #println(x)
end
