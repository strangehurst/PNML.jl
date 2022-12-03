using PNML, EzXML, ..TestUtils, JET
using PNML: firstpage, parse_file, PnmlNet, Page

#!header("Exanples")

@testset "AirplaneLD pnml file" begin
    pnml_dir = joinpath(@__DIR__, "data")
    testfile = joinpath(pnml_dir, "AirplaneLD-col-0010.pnml")
    #!@show testfile
    model = parse_file(testfile)
    @test_call  parse_file(testfile)

    @test model isa PNML.PnmlModel
    @test_call PNML.nets(model)
    netvec = PNML.nets(model)
    #@show typeof(netvec)
    @test netvec isa Vector{Any}
    @test length(netvec) == 1
    #@show typeof(netvec[1])
    @test netvec[1] isa PnmlNet
    @test netvec[1] isa PnmlNet{<:PnmlType}
    @test netvec[1].pages isa Vector{<:Page}
    @test length(netvec[1].pages) == 1
    @test !isempty(netvec[1].pages[1].transitions)
    @test !isempty(netvec[1].pages[1].arcs)
    @test !isempty(netvec[1].pages[1].places)
    @test firstpage(netvec[1]) isa PNML.Page
end
